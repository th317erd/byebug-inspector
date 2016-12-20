class OutputStream < StringIO
	def initialize(&block)
		super
		@cb = block;
	end

	def write(data)
		o = ($oldSTDOUT) ? $oldSTDOUT : $stdout;
		o.write(data);

		@cb.call(data);

		super(data);
	end
end
