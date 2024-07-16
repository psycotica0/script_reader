# I've hidden this over here because it obscures my events, having it be above
# everything

class Session
	@klasses = []
	def self.event(class_name, handler, code, *fields, &block)
		meta = Class.new do
			attr_reader :serial_proc, :deserial_proc

			def initialize
				@serial_proc = ->(*args) { args }
				@deserial_proc = ->(*args) { args }
			end

			def serial(&block)
				@serial_proc = block
			end

			def deserial(&block)
				@deserial_proc = block
			end
		end.new

		meta.instance_eval(&block) if block_given?

		klass = Struct.new(*fields) do
			define_singleton_method(:code) { code }

			define_method(:serialize) do
				data = meta.serial_proc.call(*fields.map { |field| self[field] })
				[self.class.code, *data].join(":")
			end

			define_singleton_method(:deserialize) do |str|
				parts = str.split(":")
				return unless parts.shift == code

				data = meta.deserial_proc.call(*parts)
				new(*data)
			end
		end

		const_set(class_name, klass)
		@klasses << klass

		handlers = []

		define_method(handler) do |&handler_block|
			handlers << handler_block
		end

		klass.define_singleton_method(:run_handlers) do |*args|
			handlers.each { |block| block.call(*args) }
		end
	end

	def self.handle(str)
		@klasses.each do |k|
			v = k.deserialize(str)
			return k.run_handlers(v) if v
		end

		raise "No handlers for #{str.inspect}"
	end
end
