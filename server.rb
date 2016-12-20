require 'em-websocket'
require 'json'

require_relative 'outputStream'

class InterfaceServer
  def initialize(address, port)
    @mutex = Mutex.new
    @sendQue = []
    @recvQue = []

    t = Thread.new do
      EM.run {
        @channel = EM::Channel.new

        EM.add_periodic_timer(2) {
          puts "Hello world!"
        }

        EM.add_periodic_timer(0.1) {
          @mutex.synchronize {
            @sendQue.each do |data|
              @channel.push(data.dup())
            end

            @sendQue.clear()
          }
        }

        EM::WebSocket.run(:host => '0.0.0.0', :port => 8080) { |ws|
          ws.onopen { |handshake|
            sid = @channel.subscribe { |msg| ws.send msg }

            ws.send('{"method":"Runtime.executionContextCreated","params":{"context":{"id":1,"origin":"","name":"Ruby Main Context"}}}');
            
            ws.onclose {
              @channel.unsubscribe(sid)
            }

            ws.onmessage { |msg|
              begin
                obj = JSON.parse(msg)

                mutex.synchronize {
                  recvQue.push(obj);
                }
              rescue
                #puts "Error parsing: #{msg}"
              end
            }
          }
        }
      }
    end

    t.abort_on_exception = true
    @t = t

    at_exit {
      t.join()
    }
  end

  def send(data)
    @mutex.synchronize {
      @sendQue.push(data)
    }
  end

  def remoteCall(ns, method, *args)
    a = []
    args.each do |arg|
      t = nil

      if (arg.is_a?(String) || arg.is_a?(Symbol)) then
        t = "string"
      elsif (arg.is_a?(Number))
        t = "number"
      elsif (arg.is_a?(Boolean))
        t = "boolean"
      elsif (arg.is_a?(Array))
        t = "array"
      elsif (arg.is_a?(Object))
        t = "object"
      end

      a.push({
        "type" => t,
        "value" => arg
      });
    end

    p = {
      "args" => a,
      "executionContextId" => 1,
      "timestamp" => Time.now.to_f,
      "type" => method
    };

    d = {
      "method" => ns,
      "params" => p
    };

    send(JSON.generate(d));
  end
end

