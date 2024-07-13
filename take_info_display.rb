require 'curses'
require_relative 'take_manager'

class Take
	def to_s
		return ("%03d: No sync" % [@id]) unless @sync
		"%03d: %s - %s" % [@id, @sync.offset_to(@start_time), @sync.offset_to(@end_time)]
	end
end

class TakeInfoDisplay
	def initialize(win)
		@win = win
	end

	def take=(t)
		@take = t
	end

	def move(top, left)
		@win.move(top, left)
	end

	def resize(height, width)
		@win.resize(height, width)
	end

	def noutrefresh
		@win.erase

		unless @take
			@win.noutrefresh
			return
		end

		str = @take.to_s
		@win.setpos(0, @win.maxx - str.length)
		@win << str
		@win.noutrefresh
	end

	def refresh
		noutrefresh
		Curses.doupdate
	end
end
