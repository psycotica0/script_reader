require 'curses'

require_relative 'inputbox'

class PlaybackInputForm
	def initialize(win, value)
		@win = win
		@win.keypad(true)
		label = "Playback Filename: "
		@win << label
		@input = InputBox.new(
			@win.subwin(1, @win.maxx - label.length, 0, label.length),
			0,
			value
		)
	end

	def run
		@win.noutrefresh
		@input.refresh
		loop do
			ch = @win.getch
			case ch
			when 27 # Esc
				return
			when 10 # Enter
				return @input.value
			else
				@input.handle_input(ch)
			end
		end
	ensure
		@input.close
		@win.close
	end
end
