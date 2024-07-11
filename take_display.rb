require_relative 'stylesheet'

class Take
	def attrs
		case status
		when POOR
			Stylesheet.take_poor
		when OKAY
			Stylesheet.take_okay
		when GOOD
			Stylesheet.take_good
		when TRSH
			Stylesheet.take_trsh
		else
			Stylesheet.take
		end
	end
end

class RecordingTake
	def attrs
		Stylesheet.take_rec
	end
end

class TakeDisplay
	def initialize(take_manager, win)
		@tm = take_manager
		@win = win
		@cur = 1
	end

	def selection=(sel)
		@sel = sel
		@takes = @tm.find_takes(@sel)
		@cur = @takes.length
	end

	def noutrefresh
		return unless @sel

		@win.erase
		@win.setpos(0, @win.maxx - 1)

		if @tm.recording
			# Always have the current recording selected
			@cur = @takes.length + 1
		end

		(@takes + [@tm.recording].compact).each.with_index(1).reverse_each do |take, idx|
			start = @win.curx - idx.to_s.length - 1
			@win.setpos(0, start)
			@win << " "
			attrs = take.attrs
			attrs |= Stylesheet.take_active if idx == @cur
			attrs |= Stylesheet.take_subset if take.selection != @sel
			@win.attron(attrs) do
				@win << idx.to_s
			end
			@win.setpos(0, start)
		end
		@win.noutrefresh
	end

	def refresh
		noutrefresh
		Curses.doupdate
	end

	def pick_left
		return if @takes.empty?
		return if @tm.recording # The recording is always selected
		@cur = (@cur - 1).clamp(1, @takes.length)
	end

	def pick_right
		return if @takes.empty?
		return if @tm.recording # The recording is always selected
		@cur = (@cur + 1).clamp(1, @takes.length)
	end

	def set_status(status)
		return if @takes.empty?
		return if @tm.recording # Can't mark a take until it's done
		@takes[@cur - 1].status = status
	end

	def move(y, x)
		@win.move(y, x)
	end

	def resize(height, width)
		@win.resize(height, width)
	end
end
