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
	end

	def notify(data, msg)
	end
end

Main.new();