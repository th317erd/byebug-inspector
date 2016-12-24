require 'byebug/core'
require 'byebug/processors/control_processor'
require_relative 'pluginInterface'

class ByebugPlugin < Byebug::ControlProcessor
	def initialize(context = nil)
		unless Byebug.started?
			Byebug::start
		end
		
		c = context
		if c.nil?
			c = Byebug.current_context
		end

		super(c)
	end

	def init(server = nil)
		@@server = server

		unless Byebug.started?
			Byebug::start
		end
		
		@interface = PluginInterface.new() { |command, args|
		}

		Byebug::Context.interface = @interface
		Byebug::Context.processor = self.class
	end

	def at_line
    process_commands
  end

  def at_tracing
    log "Tracing: #{context.full_location}"

    run_auto_cmds(2)
  end

  def at_breakpoint(brkpt)
    number = Byebug.breakpoints.index(brkpt) + 1

    log "DERP"
    log "Stopped by breakpoint #{number} at #{frame.file}:#{frame.line}"

    begin
	    @@server.runCommand({
				"method" => "Debugger.paused",
				"file" => "#{frame.file}",
				"line" => "#{frame.line}"
			});
		rescue => e
			log "#{e}"
		end
  end

  def at_catchpoint(exception)
    log "Catchpoint at #{context.location}: `#{exception}'"
  end

  def at_return(return_value)
    log "Return value is: #{safe_inspect(return_value)}"

    process_commands
  end

  def at_end
    process_commands
  end

	def sendCommand(command, *args)
		c = nil

		if !args.nil? && args.size > 0
			a = args.join(' ')
			c = "#{command} #{a}\n"
		else
			c = "#{command}\n"
		end

		begin
			log "Running command #{c}"

			if @proceed == false
				@interface.input.write(c)
			else
				run_cmd(c)
			end

			log "Finished command"
		rescue => e
			log "#{e}"
		end
	end
end