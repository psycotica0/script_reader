class TakeDisplay
	def initialize(take_manager, win)
		@tm = take_manager
		@win = win
	end

	def selection=(sel)
		@sel = sel
	end

	def noutrefresh
		return unless @sel

		@win.erase
		@win.setpos(0, @win.maxx - 1)
		(@tm.find_takes(@sel) + [@tm.recording].compact).each.with_index(1).reverse_each do |take, idx|
			start = @win.curx - idx.to_s.length - 1
			@win.setpos(0, start)
			@win << " "
			@win << idx.to_s
			@win.setpos(0, start)
		end
		@win.noutrefresh
	end

	def refresh
		noutrefresh
		doupdate
	end
end
