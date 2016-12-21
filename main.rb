require_relative 'server'

class Main < InterfaceServer
	def initialize()
		$oldSTDOUT = $stdout;

		$stdout = OutputStream.new() { |data|
			unless (data =~ /^\n$/)
				remoteCall("Runtime.consoleAPICalled", "log", data);
			end
		}

		super('localhost', '8080');

		$DEBUGGER_EXTRA_FILES.push(__FILE__)
	end

	def notify(data, msg)
	end
end

Main.new();