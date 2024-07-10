require 'curses'
require_relative 'stylesheet'

class SyncDisplay
	attr_accessor :sync

	def initialize(win)
		@win = win
	end

	def noutrefresh
		unless @sync
			@win.clear
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
		doupdate
	end
end
