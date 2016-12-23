class InterfaceBase
	def initialize(opts = {})
	end

	def run(command, *args)
		d = self.public_send(command, *args) if self.respond_to? command
		return d
	end
end