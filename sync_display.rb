require 'curses'
require_relative 'stylesheet'

class SyncDisplay
	attr_accessor :sync

	def initialize(win)
		@win = win
	end

	def noutrefresh
		unless @sync
			@win.erase
			@win.noutrefresh
			return
		end

		@win.setpos(0,0)
		@win.attron(Stylesheet.sync_display) do
			@win << @sync.to_s
		end
		@win.noutrefresh
	end

	def refresh
		noutrefresh
		Curses.doupdate
	end

	def move(y, x)
		@win.move(y, x)
	end

	def resize(height, width)
		@win.resize(height, width)
	end

	def clear
		@sync = nil
		refresh
	end
end
