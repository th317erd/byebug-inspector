require 'json'
require_relative 'server'

$oldSTDOUT = $stdout;
def log(*args)
	$oldSTDOUT.write(*args.join(' ') + "\n")
end 

class Main < InterfaceServer
	def initialize(opts = {})
		host = ENV.fetch("BYEBUG_INTERFACE_SERVER_ADDRESS", opts[:host]).to_s
    port = ENV.fetch("BYEBUG_INTERFACE_SERVER_PORT", opts[:port]).to_i

		$stdout = OutputStream.new() { |data|
			unless (data =~ /^\n$/)
				runCommand({
					"method" => "Runtime.consoleAPICalled",
					"args" => [data]
				});
			end
		}

		$DEBUGGER_EXTRA_FILES = [__FILE__]
		
		super({
			:host => host,
			:port => port
		});
	end

	def notify(data, msg)
	end
end

Main.new();

while true do
	puts "HERE!"
	sleep 5
end