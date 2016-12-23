require_relative 'interface'
require_relative '../plugins/byebug'

class DebuggerInterface < InterfaceBase
	def initialize(opts)
		super(opts)

		@debuggerPlugin = ByebugPlugin.new(opts)
		@scripts = {}

		loadProjectFileList()
	end

	def loadProjectFileList()
    allFiles = $LOADED_FEATURES + $DEBUGGER_EXTRA_FILES;
    allFiles.each do |name|
      if name =~ /\.rb$/
        path = File.expand_path(name)
        d = @debugger.scriptParsed({ :path => path })

        if d.nil? || d.empty?
          next
        end
      end
    end
  end

  def loadProjectFileList()
    allFiles = $LOADED_FEATURES + $DEBUGGER_EXTRA_FILES;
    allFiles.each do |name|
      if name =~ /\.rb$/
        loadProjectFile(File.expand_path(name))
      end
    end
  end

  def loadProjectFile(path)
  	begin
      file = File.open(path, "rb")
      contents = file.read
      file.close

      md5 = Digest::MD5.new
      md5.update contents
      fileHash = md5.hexdigest

      id = (@scripts.size() + 1).to_s
      lines = contents.scan(/\n/).size

      unless @scripts.key?(path)
      	s = {
      		:path => path,
      		:id => id,
      		:lines => lines,
      		:hash => fileHash,
      		:source => contents,
      		:endColumn => 0,
      		:endLine => lines
      	}

      	@scripts[path] = s
      	@scripts[id] = s
      end
    rescue
    	return
    end
  end

  def eachScript(&block)
  	@scripts.each do |key, script|
  		block.call(script)
  	end
  end

	def scriptParsed(script)
    return {
      :method => "Debugger.scriptParsed",
      :params => {
        :endColumn => script[:endColumn],
        :endLine => script[:endLine],
        :startColumn => 0,
        :startLine => 0,
        :hasSourceURL => false,
        :scriptId => script[:id],
        :isLiveEdit => false,
        :sourceMapURL => "",
        :url => script[:path],
        :hash => script[:hash],
        :executionContextId => "1"
      }
    }
  end

  def getScriptSource(opts)
  	reqID = opts['id']
  	params = opts['params']
  	scriptID = params['scriptId']

  	if @scripts.key?(scriptID)
  		s = @scripts[scriptID]

  		return {
  			:id => reqID,
  			:result => {
  				:scriptSource => s[:source]
  			}
  		}
  	end
  end

  def setBreakpointByUrl(opts)
  	log "Set breakpoint"
  	params = opts["params"]
  	file = params["url"]
  	line = params["lineNumber"]

  	log "Breakpoint #{file}:#{line}"

  	@debuggerPlugin.sendCommand("break", [file, line].join(":"))
  end
end
