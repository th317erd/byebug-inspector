class InterfaceBase
	def initialize()
	end

	def run(command, *args)
		#puts "Trying to run command: #{command}"
		d = self.public_send(command, *args) if self.respond_to? command
		return d
	end
end