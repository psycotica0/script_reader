require 'curses'
require_relative 'parser'
require_relative 'wrap_panel'
require_relative 'cursor'
require_relative 'sync_form'
require_relative 'stylesheet'
require_relative 'take_manager'
require_relative 'take_display'
require_relative 'debug_display'
require_relative 'sync_display'

if ARGV.length != 1
	puts "You have to give me a file"
	exit 1
end

class Application
	include Curses

	def run
		init_screen
		start_color

		Stylesheet.init

		curs_set(0)
		cbreak
		noecho

		begin
			p = Parser.new(File.read(ARGV[0]))
			w_margin_x = 2
			w_margin_y = 1
			w_width = cols - w_margin_x * 2
			w_height = lines - w_margin_y * 2

			@win = Window.new(w_height, w_width, w_margin_y, w_margin_x)
			@win.box
			@win.bkgd(Stylesheet.window)
			@win.keypad(true)

			wp_margin_x = 1
			wp_margin_y = 1
			wp_width = w_width - wp_margin_x * 2
			wp_height = w_height - wp_margin_y * 2
			@wp = WrapPanel.new(wp_height, wp_width, w_margin_y + wp_margin_y, w_margin_x + wp_margin_x, p)
			@wp.scroll_margin = 2
			@wp.layout

			refresh
			@win.refresh
			@wp.refresh

			@selection = p.selection
			@selection.to_start!
			@selection.activate
			@wp.refresh

			@debug_display = DebugDisplay.instance
			@debug_display.win = stdscr.derwin(1, stdscr.maxx, stdscr.maxy - 1, 0)

			@take_manager = TakeManager.new

			sd_width = "00:00:00".length
			@sync_display = SyncDisplay.new(stdscr.derwin(1, sd_width, 0, stdscr.maxx - sd_width - 1))

			tw_width = " 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15".length
			@take_display = TakeDisplay.new(
				@take_manager,
				stdscr.derwin(1, tw_width, 0, stdscr.maxx - sd_width - 1 - tw_width)
			)
			@take_display.selection = @selection
			self.timeout = 500

			loop do
				@sync_display.refresh

				case getch
				when "q"
					break
				when "j"
					@selection.move_down
					@wp.scroll_to_fit(@selection)
					@wp.noutrefresh
					@take_manager.cancel_recording
					@take_display.selection = @selection
					@take_display.noutrefresh
					doupdate
				when "k"
					@selection.move_up
					@wp.scroll_to_fit(@selection)
					@wp.noutrefresh
					@take_manager.cancel_recording
					@take_display.selection = @selection
					@take_display.noutrefresh
					doupdate
				when "J"
					@selection.spread_down
					@wp.scroll_to_fit(@selection)
					@wp.noutrefresh
					@take_manager.cancel_recording
					@take_display.selection = @selection
					@take_display.noutrefresh
					doupdate
				when "K"
					@selection.spread_up
					@wp.scroll_to_fit(@selection)
					@wp.noutrefresh
					@take_manager.cancel_recording
					@take_display.selection = @selection
					@take_display.noutrefresh
					doupdate
				when 5 # Ctrl-E
					@wp.scroll(1)
					@wp.refresh
				when 25 # Ctrl-Y
					@wp.scroll(-1)
					@wp.refresh
				when 4 # Ctrl-D
					@wp.scroll(@wp.height / 2)
					@wp.refresh
				when 21 # Ctrl-U
					@wp.scroll(-@wp.height / 2)
					@wp.refresh
				when "r"
					form = SyncForm.new(stdscr)
					result = form.run

					@sync_display.sync = Sync.new(result) if result

					stdscr.noutrefresh
					@win.box
					@win.noutrefresh
					@wp.noutrefresh
					doupdate
				when "i"
					@take_manager.start_recording(@selection)
					@take_display.refresh
				when "o"
					@take_manager.stop_recording
					@take_display.selection = @selection
					@take_display.refresh
				when "h"
					@take_display.pick_left
					@take_display.refresh
				when "l"
					@take_display.pick_right
					@take_display.refresh
				when "7"
					@take_display.set_status(Take::POOR)
					@take_display.refresh
				when "8"
					@take_display.set_status(Take::OKAY)
					@take_display.refresh
				when "9"
					@take_display.set_status(Take::GOOD)
					@take_display.refresh
				when "0"
					@take_display.set_status(Take::TRSH)
					@take_display.refresh
				end
			end
		ensure
			close_screen
		end
	end
end

Application.new.run
