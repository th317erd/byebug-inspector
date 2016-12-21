require_relative 'interface'

class DebuggerInterface < InterfaceBase
	def initialize()
		super()

		@scripts = {}
	end

	def scriptParsed(opts)
		path = opts[:path]

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
      		:id => id,
      		:lines => lines,
      		:hash => fileHash,
      		:source => contents
      	}

      	@scripts[path] = s
      	@scripts[id] = s
      end
    rescue
    	return
    end

    return {
      :method => "Debugger.scriptParsed",
      :params => {
        :endColumn => 0,
        :endLine => lines,
        :startColumn => 0,
        :startLine => 0,
        :hasSourceURL => false,
        :scriptId => id,
        :isLiveEdit => false,
        :sourceMapURL => "",
        :url => path,
        :hash => fileHash,
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
end
