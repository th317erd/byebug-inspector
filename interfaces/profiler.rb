require_relative 'interface'

class ProfilerInterface < InterfaceBase
	def enable(params)
		sendResult(params)
	end

	def setSamplingInterval(params)
		sendResult(params)
	end
end