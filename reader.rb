require 'curses'
require_relative 'parser'
require_relative 'wrap_panel'
require_relative 'cursor'
require_relative 'sync_form'
require_relative 'stylesheet'
require_relative 'take_manager'
require_relative 'take_display'
require_relative 'take_info_display'
require_relative 'debug_display'
require_relative 'sync_display'
require_relative 'session'
require_relative 'output'
require_relative 'fine_tune_form'
require_relative 'playback_file_form'

if ARGV.length != 1 && ARGV.length != 2
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

		# The delay a keypad'd app waits before declaring an escape key was hit
		# I want it short (in ms) so escape feels responsive
		self.ESCDELAY = 10

		begin
			@p = Parser.new(File.read(ARGV[0]))

			@win = new_win
			@win.bkgd(Stylesheet.window)
			@win.keypad(true)

			@wp = WrapPanel.new(1, 1, 0, 0, @p)
			@wp.scroll_margin = 2

			@debug_display = DebugDisplay.instance
			@debug_display.win = new_win

			@take_manager = TakeManager.new

			@sync_display = SyncDisplay.new(new_win)

			@take_display = TakeDisplay.new(@take_manager, new_win)

			@take_info_display = TakeInfoDisplay.new(new_win)
			@take_display.on_take_selected do |take|
				@take_info_display.take = take
				@take_info_display.noutrefresh
			end

			self.timeout = 1000 / 30 # 30 FPS

			layout
			full_refresh

			@selection = @p.full_selection.at_start
			@selection.activate

			@take_display.selection = @selection
			@take_display.noutrefresh

			@wp.scroll_to_fit(@selection)
			@wp.noutrefresh

			doupdate

			@session = Session.new(File.open(
				ARGV[1] || "#{ARGV[0]}.session.001",
				File::Constants::RDWR | File::Constants::CREAT
			))

			@session.on_set_sync do |ss|
				@sync_display.sync = Sync.new(ss.start_time)
				@sync_display.refresh
			end

			@session.on_clear_sync do |cs|
				@sync_display.clear
			end

			@session.on_new_take do |nt|
				selection = @p.get_selection(nt.selection_start_id, nt.selection_final_id)
				@take_manager.new_take(@sync_display.sync, nt.start_time, nt.end_time, selection)
				selection.mark_recorded
				@wp.noutrefresh
				@take_display.reload!
				@take_display.noutrefresh
				doupdate
			end

			@session.on_take_status do |ts|
				t = @take_manager.get_take(ts.take_id)
				next unless t
				t.status = ts.status
				@take_display.reload!
				@take_display.select_take(t)
				@take_display.refresh
			end

			@session.on_fine_tune do |ft|
				@output.global_offset_ms = ft.offset_ms
			end

			@session.on_playback_file do |pf|
				@output.audio_filename = pf.filename
			end

			@output = Output.new

			@session.resume!

			loop do
				@sync_display.refresh
				@output.update_state

				case getch
				when "q"
					break
				when "j"
					change_selection(@selection.move_down)
					doupdate
				when "k"
					change_selection(@selection.move_up)
					doupdate
				when "J"
					change_selection(@selection.spread_down)
					doupdate
				when "K"
					change_selection(@selection.spread_up)
					doupdate
				when "."
					t = @take_manager.most_recent_take
					next unless t
					if t.selection == @selection && @toggle_selection
						change_selection(@toggle_selection, true)
						@take_display.select_take(t)
						@take_display.noutrefresh
						doupdate
					elsif t.selection != @selection
						change_selection(t.selection, true, @selection)
						@take_display.select_take(t)
						@take_display.noutrefresh
						doupdate
					end
				when KEY_CTRL_E
					@wp.scroll(1)
					@wp.refresh
				when KEY_CTRL_Y
					@wp.scroll(-1)
					@wp.refresh
				when KEY_CTRL_D
					@wp.scroll(@wp.height / 2)
					@wp.refresh
				when KEY_CTRL_U
					@wp.scroll(-@wp.height / 2)
					@wp.refresh
				when "s"
					form = SyncForm.new(new_win)
					result = form.run
					full_refresh

					@session << Session::SetSync.new(Time.now - result.to_i) if result
				when "S"
					@session << Session::ClearSync.new(Time.now)
				when "-"
					next unless @sync_display.sync
					@session << Session::SetSync.new(@sync_display.sync.offset(-0.05))
				when "+"
					next unless @sync_display.sync
					@session << Session::SetSync.new(@sync_display.sync.offset(0.05))
				when "i"
					@toggle_selection = nil
					@take_manager.start_recording(@selection)
					@take_display.refresh
				when "o"
					r = @take_manager.stop_recording
					@session << r if r
				when "h"
					@take_display.pick_left
					@take_display.refresh
					@toggle_selection = nil
					@output.stop_playing
				when "l"
					@take_display.pick_right
					@take_display.refresh
					@toggle_selection = nil
					@output.stop_playing
				when "m"
					t = @take_display.current_take
					next unless t
					if t.selection == @selection && @toggle_selection
						change_selection(@toggle_selection, true)
						@take_display.select_take(t)
						@take_display.noutrefresh
						doupdate
					elsif t.selection != @selection
						change_selection(t.selection, true, @selection)
						@take_display.select_take(t)
						@take_display.noutrefresh
						doupdate
					end
				when "7"
					t = @take_display.current_take
					@session << Session::TakeStatus.new(t.id, Take::POOR) if t
				when "8"
					t = @take_display.current_take
					@session << Session::TakeStatus.new(t.id, Take::OKAY) if t
				when "9"
					t = @take_display.current_take
					@session << Session::TakeStatus.new(t.id, Take::GOOD) if t
				when "0"
					t = @take_display.current_take
					@session << Session::TakeStatus.new(t.id, Take::TRSH) if t
				when "p"
					@output.play_takes([@take_display.current_take].compact)
				when "f"
					r = PlaybackInputForm.new(Window.new(1, cols / 2, 0, 0), @output.audio_filename).run
					@session << Session::PlaybackFile.new(r) if r
					full_refresh
				when "F"
					t = @take_display.current_take
					next unless t
					f = FineTuneForm.new(t, @output)
					r = f.run
					@session << Session::FineTune.new(r) if r
					full_refresh
				when KEY_RESIZE, KEY_CTRL_L
					layout
					full_refresh
				end
			end
		ensure
			@output.stop_playing(true)
			close_screen
			@session.close if @session
		end
	end

	def layout
		w_margin_x = 2
		w_margin_y = 1
		w_width = cols - w_margin_x * 2
		w_height = lines - w_margin_y * 2

		@win.move(w_margin_y, w_margin_x)
		@win.resize(w_height, w_width)

		wp_margin_x = 1
		wp_margin_y = 1
		wp_width = w_width - wp_margin_x * 2
		wp_height = w_height - wp_margin_y * 2
		@wp.move(w_margin_y + wp_margin_y, w_margin_x + wp_margin_x)
		@wp.resize(wp_height, wp_width)
		@wp.scroll_to_fit(@selection) if @selection

		@debug_display.win.move(stdscr.maxy - 1, 0)
		@debug_display.win.resize(1, stdscr.maxx)

		sd_width = "00:00:00".length
		@sync_display.move(0, stdscr.maxx - sd_width - w_margin_x)
		@sync_display.resize(1, sd_width)

		tw_width = " 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15".length
		@take_display.move(0, stdscr.maxx - sd_width - w_margin_x - 1 - tw_width)
		@take_display.resize(1, tw_width)

		ti_width = "000: 00:00:00 - 00:00:00".length
		@take_info_display.move(lines - 1, cols - w_margin_x - ti_width)
		@take_info_display.resize(1, ti_width)
	end

	def change_selection(new_sel, activate=false, toggle=nil)
		@selection.deactivate if activate
		@selection = new_sel
		@selection.activate if activate
		@wp.scroll_to_fit(@selection)
		@wp.noutrefresh
		@take_manager.cancel_recording
		@toggle_selection = toggle
		@take_display.selection = @selection
		@take_display.noutrefresh
		@output.stop_playing
	end

	def full_refresh
		erase
		stdscr.noutrefresh
		@win.box
		@win.noutrefresh
		@wp.noutrefresh
		@sync_display.noutrefresh
		@take_display.noutrefresh
		@take_info_display.noutrefresh
		doupdate
	end

	def new_win
		Window.new(1, 1, 0, 0)
	end
end

Application.new.run
