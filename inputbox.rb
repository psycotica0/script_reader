require 'curses'

class InputBox
	include Curses

	attr_reader :value

	def initialize(win, style, value)
		@win = win
		@win.keypad(true)
		@style = style
		@value = value.dup || ""
		@cursor = @value.length
		@scroll = 0
		scroll_to_cursor
	end

	def scroll_to_cursor
		str_min = @scroll
		str_max = (@win.maxx - 1) + @scroll

		# If it's in the middle area, it's unconditionally fine
		return if @cursor.between?(str_min + 1, str_max - 1)

		if @cursor < str_min
			@scroll -= str_min - @cursor
		elsif @cursor > str_max
			@scroll += @cursor - str_max
		end

		str_min = @scroll
		str_max = (@win.maxx - 1) + @scroll

		if @cursor == str_min && @scroll > 0
			# If there's characters off to the left, then move up by one to dodge
			# the "<"
			@scroll -= 1
		elsif @cursor == str_max && (@scroll + @win.maxx) < @value.length
			# If there's characters off to the right, then move back by one to
			# dodge the "<"
			@scroll += 1
		end
	end

	def noutrefresh
		visible_min = @scroll > 0 ? 1 : 0
		visible_max = (@scroll + @win.maxx) >= @value.length ? @win.maxx - 1 : @win.maxx - 2

		@win.setpos(0, 0)
		@win.attron(@style) do
			0.upto(@win.maxx - 1) do |i|
				if i < visible_min
					@win.attron(A_BOLD) do
						@win << "<"
					end
				elsif i > visible_max
					@win.attron(A_BOLD) do
						@win << ">"
					end
				else
					pos = i + @scroll
					@win.attron(pos == @cursor ? A_STANDOUT : 0) do
						@win << (pos >= @value.length ? " " : @value[pos])
					end
				end
			end
		end

		@win.noutrefresh
	end

	def handle_input(ch)
		case ch
		when String
			@value.insert(@cursor, ch)
			@cursor += 1
			scroll_to_cursor
			refresh
		when KEY_BACKSPACE, KEY_DC, 127
			if @cursor > 0
				@value.slice!(@cursor - 1)
				@cursor -= 1
				scroll_to_cursor
				refresh
			end
		when KEY_LEFT
			@cursor = (@cursor - 1).clamp(0, @value.length)
			scroll_to_cursor
			refresh
		when KEY_RIGHT
			@cursor = (@cursor + 1).clamp(0, @value.length)
			scroll_to_cursor
			refresh
		when KEY_CTRL_A
			@cursor = 0
			scroll_to_cursor
			refresh
		when KEY_CTRL_E
			@cursor = @value.length
			scroll_to_cursor
			refresh
		end
	end

	def refresh
		noutrefresh
		Curses.doupdate
	end

	def close
		@win.close
	end
end
