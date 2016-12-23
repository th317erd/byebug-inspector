require 'byebug/core'
require 'socket'
include Socket::Constants

class ByebugPlugin
	def initialize(opts)
		@sendQue = []
		@host = opts[:host]
		@port = ENV.fetch("BYEBUG_SERVER_PORT", opts[:port]).to_i
		@port += 1

		@mutex = Mutex.new

		Byebug.start_server @host, @port
		log "Byebug server started #{@host}:#{@port}"
		
		t = Thread.new do
			log 'Connecting to byebug server...'
	    
			socket = Socket.new(AF_INET, SOCK_STREAM, 0)
			sockaddr = Socket.sockaddr_in(@port, @host)
			begin
				socket.connect_nonblock(sockaddr)
			rescue IO::WaitWritable
				IO.select(nil, [socket])
				begin
					socket.connect_nonblock(sockaddr)
				rescue Errno::EINVAL
					retry
				rescue Errno::EISCONN
					log "Failed!"
					return
				end
			end

			log "Connected!"

	    while true do
	    	log "Looping"
	    	# if @sendQue.size > 0
	    	# 	log "trying Doing que"
		    # 	@mutex.synchronize {
		    # 		log "Doing que"
		    # 		@sendQue.each { |item|
		    # 			command = item[:command]
		    # 			args = item[:args]

		    # 			if !args.nil? && args.size > 0
		    # 				a = args.join(' ')
		    # 				log "Sending to socket: #{command} #{a}\n"
		    # 				socket.write("#{command} #{a}\n")
		    # 			else
		    # 				log "Sending to socket: #{command}\n"
		    # 				socket.write("#{command}\n")
		    # 			end
		    # 		}
		    # 	}
		    # end

		    log "Read socket"
		    begin
	    		results = socket.read_nonblock(1024)
	    	rescue IO::WaitReadable
	    	end
	    	log "Done"

	    	sleep 0.5
	    	unless results.nil? || results.empty?
	    		log "Got from socket: " + results
	    	end
	    end

	    socket.close
		end

		t.abort_on_exception = true
    @t = t

    at_exit {
      t.join()
    }
	end

	def sendCommand(command, *args)
		@mutex.synchronize {
			@sendQue.push({
				:command => command,
				:args => args
			});
		}
	end
end