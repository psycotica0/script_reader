require 'curses'
require_relative 'stylesheet'

class FineTuneForm
	include Curses

	def initialize(take, output)
		@take = take
		# This will allow me to trial changing the offset
		@output = output.dup
		@mockup = <<~MOCK.lines.map(&:strip)
			+---------------------------+
			|         Fine Tune         |
			|    [--------+--------]    |
			+---------------------------+
		MOCK

		top = (lines - @mockup.length) / 2
		left = (cols - @mockup.first.length) / 2
		@win = Window.new(@mockup.length, @mockup.first.length, top, left)

		bar_row = @mockup.find_index { |r| r.include?("[") }
		bar_start = @mockup[bar_row].index("[")
		bar_stop = @mockup[bar_row].index("]") + 1
		@bar = @win.subwin(1, bar_stop - bar_start, top + bar_row, left + bar_start)
	end

	def run
		@win.noutrefresh
		@bar.noutrefresh

		@win.bkgd(Stylesheet.fine_tune_window)
		@bar.bkgd(Stylesheet.fine_tune_bar)

		@win.setpos(1, 0)
		@win << @mockup[1]
		@win.box

		draw_bar

		@win.noutrefresh
		@bar.noutrefresh
		doupdate

		loop do
			@output.update_state

			case getch
			when "q", 27 # Esc
				break
			when 10 # Enter
				return @output.global_offset_ms
			when "k"
				@output.play_takes([@take])
			when "h"
				@output.global_offset_ms -= 10
				draw_bar
				@bar.refresh
				@output.play_takes([@take])
			when "H"
				@output.global_offset_ms -= 100
				draw_bar
				@bar.refresh
				@output.play_takes([@take])
			when "l"
				@output.global_offset_ms += 10
				draw_bar
				@bar.refresh
				@output.play_takes([@take])
			when "L"
				@output.global_offset_ms += 100
				draw_bar
				@bar.refresh
				@output.play_takes([@take])
			end
		end
	ensure
		@output.stop_playing(true)
		@bar.close
		@win.close
	end

	def draw_bar
		@bar.erase
		dashes = (@bar.maxx - 3) / 2
		per_dash = 2000 / dashes
		selected = (@output.global_offset_ms.to_f / per_dash).round.to_i

		@bar.attron(Stylesheet.fine_tune_bar) do
			@bar << "["
			(-dashes..dashes).each do |i|
				@bar.attron(selected == i ? Stylesheet.fine_tune_bar_selected : 0) do
					@bar << (i == 0 ? "+" : "-")
				end
			end
			@bar << "]"
		end
	end
end
