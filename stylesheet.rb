require 'curses'

class Stylesheet
	class << self
		include Curses

		attr_accessor :window, :script_text, :active_script_text, :sync_form_label, :sync_form_input, :debug

		def init
			cwin = col(COLOR_WHITE, COLOR_BLUE)
			@window = color_pair(cwin)

			cscript = col(COLOR_WHITE, COLOR_BLACK)
			@script_text = color_pair(cscript)
			@active_script_text = @script_text | A_STANDOUT

			csync = col(COLOR_RED, COLOR_BLACK)
			@sync_form_label = color_pair(csync) | A_BOLD
			@sync_form_input = @sync_form_label

			cdebug = col(COLOR_WHITE, COLOR_RED)
			@debug = color_pair(cdebug)
		end

		def col(fore, back)
			@i ||= 1
			init_pair(@i, fore, back)
			r = @i
			@i += 1

			return r
		end
	end
end
