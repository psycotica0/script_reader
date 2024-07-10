require 'curses'
require_relative 'parser'
require_relative 'wrap_panel'
require_relative 'cursor'
require_relative 'sync_form'

if ARGV.length != 1
	puts "You have to give me a file"
	exit 1
end

include Curses

# I stole this from the source
A_ITALIC=-2147483648

init_screen
start_color

C_WIN = 1
init_pair(C_WIN, COLOR_WHITE, COLOR_BLUE)

C_PANEL = 2
init_pair(C_PANEL, COLOR_WHITE, COLOR_BLACK)

C_ACTIVE = 3
init_pair(C_ACTIVE, COLOR_RED, COLOR_BLACK)

curs_set(0)
cbreak
noecho

begin
	p = Parser.new(File.read(ARGV[0]))
	w_margin_x = 2
	w_margin_y = 1
	w_width = cols - w_margin_x * 2
	w_height = lines - w_margin_y * 2

	win = Window.new(w_height, w_width, w_margin_y, w_margin_x)
	win.box
	win.bkgd(color_pair(C_WIN))
	win.keypad(true)

	wp_margin_x = 1
	wp_margin_y = 1
	wp_width = w_width - wp_margin_x * 2
	wp_height = w_height - wp_margin_y * 2
	wp = WrapPanel.new(wp_height, wp_width, w_margin_y + wp_margin_y, w_margin_x + wp_margin_x, p)
	wp.scroll_margin = 2
	wp.layout

	refresh
	win.refresh
	wp.refresh

	selection = p.selection
	selection.to_start!
	selection.activate
	wp.refresh

	loop do
		case getch
		when "q"
			break
		when "j"
			selection.move_down
			wp.scroll_to_fit(selection)
			wp.refresh
		when "k"
			selection.move_up
			wp.scroll_to_fit(selection)
			wp.refresh
		when "J"
			selection.spread_down
			wp.scroll_to_fit(selection)
			wp.refresh
		when "K"
			selection.spread_up
			wp.scroll_to_fit(selection)
			wp.refresh
		when 5 # Ctrl-E
			wp.scroll(1)
			wp.refresh
		when 25 # Ctrl-Y
			wp.scroll(-1)
			wp.refresh
		when 4 # Ctrl-D
			wp.scroll(wp.height / 2)
			wp.refresh
		when 21 # Ctrl-U
			wp.scroll(-wp.height / 2)
			wp.refresh
		when "r"
			form = SyncForm.new(stdscr)
			result = form.run

			stdscr.noutrefresh
			win.box
			win.noutrefresh
			wp.noutrefresh
			doupdate
		end
	end
ensure
	close_screen
end
