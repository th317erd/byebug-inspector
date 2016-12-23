require_relative 'interface'

class RuntimeInterface < InterfaceBase
	def consoleAPICalled(opts)
		args = opts["args"]

		remoteCall("Runtime.consoleAPICalled", "log", *args);
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

    return {
      "method" => ns,
      "params" => p
    };
  end
end