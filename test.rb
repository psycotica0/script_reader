require 'curses'

include Curses

# I stole this from the source
A_ITALIC=-2147483648

init_screen
start_color

init_pair(1, 1, 0)
init_pair(2, COLOR_WHITE, COLOR_BLUE)
curs_set(0)
cbreak
noecho

begin
	win = Window.new(0, 0, 1, 2)
	win.box
	win.bkgd(color_pair(2))
	win.setpos(1,1)
	win.attron(color_pair(1)) { win << "Hello " }
	win.attron(color_pair(1) | A_BOLD) { win << "Hello " }
	win.attron(color_pair(1) | A_STANDOUT) { win << "Hello " }
	win.attron(color_pair(1) | A_UNDERLINE) { win << "Hello " }
	win.attron(color_pair(1) | A_ITALIC) { win << "Hello " }
	cbreak
	win.keypad(true)
	refresh
	win.refresh
	self.timeout = 10000
	$ch = getch
ensure
	close_screen
end

p $ch
