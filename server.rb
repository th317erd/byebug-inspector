require 'em-websocket'
require 'json'
require 'digest'

require_relative 'outputStream'
require_relative 'interfaces/debugger'
require_relative 'interfaces/runtime'
require_relative 'interfaces/profiler'

class InterfaceServer
  def initialize(opts)
    host = opts[:host]
    port = opts[:port]

    if host.nil? || host.empty?
      host = '0.0.0.0'
    end

    if port.nil? || port == 0
      port = 9229
    end

    opts = opts.merge({
      :host => host,
      :port => port
    });

    @mutex = Mutex.new

    @debugger = DebuggerInterface.new(self, opts)
    @runtime = RuntimeInterface.new(self, opts)
    @profiler = ProfilerInterface.new(self, opts)

    @interfaces = {
      "Debugger" => @debugger,
      "Runtime" => @runtime,
      "Profiler" => @profiler
    }

    @channel = EM::Channel.new

    t = Thread.new do
      EM.run {
        # EM.add_periodic_timer(10) {
        #   puts "Hello world!"
        # }

        EM::WebSocket.run(:host => host, :port => port) { |ws|
          ws.onopen { |handshake|
            sid = 0

            @mutex.synchronize {
              sid = @channel.subscribe { |msg|
                ws.send msg
              }
            }

            ws.send('{"method":"Runtime.executionContextCreated","params":{"context":{"id":1,"origin":"","name":"Ruby Main Context"}}}');

            ws.onclose {
              @mutex.synchronize {
                @channel.unsubscribe(sid)
              }
            }

            ws.onmessage { |msg|
              begin
                obj = JSON.parse(msg)
                runCommand(obj);
              rescue
                #puts "Error parsing: #{msg}"
              end
            }

            #For some reason things break if I don't wait a small amount of time
            #before sending the script list
            EM.add_timer(0.1) {
              sendScripts()
            }
          }
        }
      }
    end

    t.abort_on_exception = true
    @t = t

    $applicationShutdown = false
    at_exit {
      log "Stopping!!!"
      $applicationShutdown = true
      t.join()
    }
  end

  def send(data)
    if data.nil? || data.empty? then return end

    d = data
    unless d.is_a?(String)
      d = JSON.generate(data)
    end

    log "Sending data: #{d}"

    @channel.push(d)
  end

  def runCommand(obj)
    method = obj["method"];

    if method.nil? || method.empty? then return end

    log "Running command #{method}"
    prefix = ""
    method = method.sub(/^(\w+)\./) { |m|
      prefix = $1
      next ""
    }

    if method.nil? || method.empty? then return end

    d = nil

    interface = @interfaces[prefix]
    unless interface.nil?
      d = interface.run(method, obj)
      send(d)
    end
  end

  def sendScripts()
    @debugger.eachScript do |script|
      d = @debugger.scriptParsed(script)
      send(d)
    end
  end
end

