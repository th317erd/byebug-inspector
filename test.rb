require 'byebug'

module MyByebug
	extend Byebug
	
	def self.included(base)
    base.send :extend, Byebug
  end

  def self.attach
  	require 'byebug/core'

  	unless started?
  		self.mode = :attached

  		start
  	end

  	current_context.step_out(3, true)
  end
end

MyByebug.attach