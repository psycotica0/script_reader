class Duration
	def self.parse(str)
		seconds, minutes, hours = str.split(":").map {|s| s.to_i}.reverse
		hours ||= 0
		minutes ||= 0
		total = seconds + (minutes * 60) + (hours * 60 * 60)

		new(total)
	end
	
	def initialize(n)
		@n = n
	end

	def to_s(precision=0)
		hours, rest = @n.divmod(3600)
		minutes, seconds = rest.divmod(60)

		second_width = precision == 0 ? 2 : 3 + precision
		"%02d:%02d:%0*.*f" % [hours, minutes, second_width, precision, seconds]
	end

	def to_i
		@n
	end

	def to_f
		@n
	end

	# Shifts the hh:mm:ss display
	def shiftl!(new_digit = 0)
		# First we deconstruct into ab:cd:ef
		# Then we shift to
		# bc:de:f0
		# then rebuild
		ab, rest = @n.divmod(60 * 60)
		c, rest = rest.divmod(60 * 10)
		d, rest = rest.divmod(60)
		e, f = rest.divmod(10)

		@n = (ab * 10 + c) * (60 * 60) + (d * 10 + e) * 60 + f * 10 + new_digit
	end

	def shiftr!
		# First we deconstruct into ab:cd:ef
		# Then we shift to
		# 0a:bc:de
		# then rebuild
		a, rest = @n.divmod(60 * 60 * 10)
		b, rest = rest.divmod(60 * 60)
		c, rest = rest.divmod(60 * 10)
		d, rest = rest.divmod(60)
		e, f = rest.divmod(10)

		@n = (a / 10) * (60 * 60) + (b * 10 + c) * 60 + (d * 10 + e)
	end

	def +(other)
		Duration.new(@n + other)
	end
end

class Sync
	def initialize(start_time)
		@start_time = start_time
	end

	def to_s
		Duration.new(to_i).to_s
	end

	def to_i
		Time.now - @start_time
	end

	def offset_to(time)
		Duration.new(time - @start_time)
	end

	# Return a new time based on this one plus the given fractional second
	# offset
	def offset(s)
		@start_time + s
	end
end
