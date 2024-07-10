require 'curses'
require_relative 'sync'
require_relative 'stylesheet'

class SyncForm
	include Curses

	def initialize(win)
		@label = "Sync Time: "
		@duration = Duration.new(0)
		@win = win.derwin(1, @label.length + 1 + 10, 0, 0)
	end

	def run
		@win.refresh
		@win.setpos(1, 1)
		@win.attron(Stylesheet.sync_form_label) do
			@win << @label
		end
		@win.refresh

		begin
			loop do
				draw
				ch = getch
				case ch
				when 'q', 27 # Esc
					return nil
				when 10 # Enter
					return @duration
				when '0'..'9'
					@duration.shiftl!(ch.to_i)
				when KEY_BACKSPACE, KEY_DC, 127
					@duration.shiftr!
				end
			end
		ensure
			@win.erase
			@win.close
		end
	end

	def draw
		@r ||= 1
		@win.setpos(0, @label.length + 1)
		@win.attron(Stylesheet.sync_form_input) do
			@win << @duration.to_s
		end
		@win.refresh
		@r += 1
	end
end
