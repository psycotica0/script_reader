require 'curses'

class Stylesheet
	# Italic: I stole this from the source
	A_ITALIC = -2147483648

	class << self
		include Curses

		attr_accessor :window, :script_text, :active_script_text, :unrecorded_script_text, :sync_form_label, :sync_form_input, :debug, :sync_display
		attr_accessor :take, :take_poor, :take_okay, :take_good, :take_trsh, :take_rec, :take_subset, :take_active
		attr_accessor :fine_tune_window, :fine_tune_bar, :fine_tune_bar_selected

		def init
			cwin = col(COLOR_WHITE, COLOR_BLUE)
			@window = color_pair(cwin)

			cscript = col(COLOR_WHITE, COLOR_BLACK)
			@script_text = color_pair(cscript)
			@active_script_text = @script_text | A_STANDOUT
			@unrecorded_script_text = A_DIM

			csync = col(COLOR_RED, COLOR_BLACK)
			@sync_form_label = color_pair(csync) | A_BOLD
			@sync_form_input = @sync_form_label

			cdebug = col(COLOR_WHITE, COLOR_RED)
			@debug = color_pair(cdebug)

			@sync_display = color_pair(col(COLOR_WHITE, COLOR_BLACK))

			init_takes

			init_fine_tune
		end

		def init_takes
			ctake = col(COLOR_WHITE, COLOR_BLACK)
			@take = color_pair(ctake)

			cp = col(COLOR_RED, COLOR_BLACK)
			@take_poor = color_pair(cp)

			co = col(COLOR_YELLOW, COLOR_BLACK)
			@take_okay = color_pair(co)

			cg = col(COLOR_GREEN, COLOR_BLACK)
			@take_good = color_pair(cg)

			ct = col(COLOR_WHITE, COLOR_BLACK)
			@take_trsh = color_pair(ct) | A_DIM

			cr = col(COLOR_RED, COLOR_WHITE)
			@take_rec = color_pair(cr) | A_BLINK

			@take_subset = A_UNDERLINE

			@take_active = A_STANDOUT
		end

		def init_fine_tune
			@fine_tune_window = color_pair(col(COLOR_WHITE, COLOR_BLUE))
			@fine_tune_bar = color_pair(col(COLOR_WHITE, COLOR_CYAN))
			@fine_tune_bar_selected = color_pair(col(COLOR_WHITE, COLOR_YELLOW))
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
