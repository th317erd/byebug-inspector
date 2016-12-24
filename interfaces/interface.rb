class InterfaceBase
	def initialize(server = nil, opts = {})
	end

	def run(command, *args)
		d = self.public_send(command, *args) if self.respond_to? command
		return d
	end

	def sendResult(params, result = nil)
		id = params["id"]
		r = result

		if r.nil?
			r = {}
		end

		return {
			:id => id,
			:result => r
		}
	end
end