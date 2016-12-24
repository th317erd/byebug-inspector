require_relative 'interface'
require_relative '../plugins/byebug'

class DebuggerInterface < InterfaceBase
	def initialize(server, opts)
		super(opts)

		p = ByebugPlugin.new()
		p.init(server)
		@debuggerPlugin = p

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

  def enable(params)
  	sendResult(params)
  end

  def setPauseOnExceptions(params)
  	sendResult(params)
  end

  def setAsyncCallStackDepth(params)
  	sendResult(params)
  end

  def setBlackboxPatterns(params)
  	sendResult(params)
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

  def getScriptSource(params)
  	p = params['params']
  	scriptID = p['scriptId']

  	if @scripts.key?(scriptID)
  		s = @scripts[scriptID]

  		return sendResult(params, {
				:scriptSource => s[:source]
			})
  	end
  end

  def setBreakpointByUrl(params)
  	log "Set breakpoint"
  	params = params["params"]
  	file = params["url"]
  	line = params["lineNumber"] + 1

  	log "Breakpoint #{file}:#{line}"

  	@debuggerPlugin.sendCommand("break", [file, line].join(":"))
  end

  def paused(params)
  	file = params["file"]
  	line = params["line"]

  	return {
  		:method => "Debugger.paused",
  		:params => {
  			:hitBreakpoints => ["#{file}:#{line}:0"],
  			:reason => "other"
  		}
  	}
  end
end
