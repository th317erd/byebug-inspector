require 'byebug/core'
class PluginInterface < Byebug::Interface
	def initialize(&block)
		super()

		@block = block;
		@input = StringIO.new
		@output = StringIO.new
		@error = nil
	end

	def prepare_input(prompt)
		begin
    	line = @input.readline(prompt)
    	log "Got input line #{line}"
    	return unless line

    	last_if_empty(line)
    rescue
    	sleep 0.01
    end

    ''
  end

  def push(opts)
  	@block.call('interfacePush', [opts])
  end

	def errmsg(message)
		log "Debugger Error: #{message}"
	end

	def puts(message)
		@output.puts message
		@block.call('interfacePuts', [message])
	end

	def print(message)
		@output.print message
		@block.call('interfacePrint', [message])
	end

	def confirm()
		true
	end

	def close()
		@input.close
		@output.close
	end
end
