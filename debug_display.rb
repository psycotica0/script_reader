require 'singleton'
require_relative 'stylesheet'

class DebugDisplay
	include Singleton

	attr_writer :win

	def dump(str)
		return unless @win

		if Array === str
			str = str.inspect
		end

		@win.setpos(0,0)
		@win.attron(Stylesheet.debug) do
			@win << str.to_s
		end
		@win.clrtoeol
		@win.refresh
	end

	def self.dump(str)
		instance.dump(str)
	end
end
