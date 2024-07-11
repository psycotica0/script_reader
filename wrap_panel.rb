require 'curses'
require_relative 'parser'
require_relative 'stylesheet'

class Parser
	def layout(pad, width)
		@chunks.each do |chunk|
			chunk.layout(pad, width)
		end
	end
end

class Line
	def layout(pad, width)
		margin = 5
		pad << "%03d| " % line_num
		@sents.each_with_index do |s, idx|
			if s.pre_space.nil? && idx > 0
				# We check if there already is one because we don't
				# want to make a new one on re-layout
				s.pre_space = InterSentenceSpace.new
			end
			s.layout(pad, width, margin)
		end
		pad.clrtoeol
		pad.setpos(pad.cury + 1, 0)
	end
end

class InterSentenceSpace
	def layout(pad, margin)
		# Capture for redraws
		@pad, @margin = pad, margin
		@x, @y = pad.curx, pad.cury
		draw
	end

	def draw
		return if @x >= @pad.maxy || @x < @margin

		@pad.attron(@active ? Stylesheet.active_script_text : Stylesheet.script_text) do
			@pad << " "
		end
	end

	def redraw
		@pad.setpos(@y, @x)
		draw
	end

	def activate
		@active = true
	end

	def deactivate
		@active = false
	end
end

class Sentence
	attr_accessor :pre_space

	def layout(pad, width, margin)
		@pre_space.layout(pad, margin) if @pre_space

		@spans.each do |s|
			s.layout(pad, width, margin)
		end
	end

	def redraw
		@spans.each do |s|
			s.redraw
		end
	end

	def activate
		@spans.each do |s|
			s.activate
		end
	end

	def deactivate
		@spans.each do |s|
			s.deactivate
		end
	end

	def top
		@spans.first.top
	end

	def bottom
		@spans.last.bottom
	end
end

class Span
	def attrs
		Curses::A_NORMAL
	end

	def layout(pad, width, margin)
		# Save these for redraw later
		@x, @y = pad.curx, pad.cury
		@pad, @width, @margin = pad, width, margin
		draw
		@y2 = pad.cury
	end

	def draw
		to_s.scan(/.+?(?=\s|$)/).each do |word|
			if @pad.curx + word.length > @width
				@pad.clrtoeol
				@pad.setpos(@pad.cury + 1, @margin)
				word.lstrip!
			end

			# The last row lines up perfectly with the end and wrapped
			if @pad.curx < @margin
				@pad.setpos(@pad.cury, @margin)
				word.lstrip!
			end

			@pad.attron(attrs | active_attr) do
				@pad << word
			end
		end
	end

	def redraw
		@pad.setpos(@y, @x)
		draw
	end

	def active_attr
		@active ? Stylesheet.active_script_text : Stylesheet.script_text
	end

	def activate
		@active = true
	end

	def deactivate
		@active = false
	end

	def top
		@y
	end

	def bottom
		@y2
	end
end

class Emph
	def attrs
		Stylesheet::A_ITALIC
	end
end

class Strong
	def attrs
		Curses::A_BOLD
	end
end

class CodeBlock
	def layout(pad, width)
	end
end

class BlankLine
	def layout(pad, width)
		pad << "%03d| " % line_num
		pad.clrtoeol
		pad.setpos(pad.cury + 1, 0)
	end
end

class WrapPanel
	HEIGHT = 5000

	attr_accessor :default_style, :active_style, :scroll_margin
	attr_reader :pad, :height

	def initialize(height, width, top, left, p)
		@height = height
		@width = width
		@left = left
		@top = top
		@parse = p
		@pad = Curses::Pad.new(HEIGHT, width)
		@scroll_pos = 0
	end

	def layout
		@parse.layout(@pad, @width)
	end

	def noutrefresh
		@pad.noutrefresh(@scroll_pos, 0, @top, @left, @top + @height - 1, @left + @width)
	end

	def refresh
		@pad.refresh(@scroll_pos, 0, @top, @left, @top + @height - 1, @left + @width)
	end

	def scroll(n)
		@scroll_pos += n

		@scroll_pos = 0 if @scroll_pos < 0
	end

	def scroll_to_fit(selection)
		scroll_to_range(selection.top, selection.bottom)
	end

	def scroll_to_range(top, bottom)
		# Shouldn't happen in real usage
		# but if our selection is bigger than our window, don't scroll
		return if bottom - top > (@height - @scroll_margin * 2)

		etop = @scroll_pos + @scroll_margin
		ebottom = @scroll_pos + @height - @scroll_margin - 1

		# If it's already on the screen the way we want, then do nothing
		return if top >= etop && bottom <= ebottom

		if top < etop
			@scroll_pos = [top - @scroll_margin, 0].max
		elsif bottom > ebottom
			@scroll_pos = bottom + @scroll_margin - @height + 1
		end
	end

	def move(top, left)
		@top = top
		@left = left
	end

	def resize(height, width)
		@height = height
		@width = width
		@pad.erase
		@pad.setpos(0,0)
		@pad.resize(HEIGHT, width)
		layout
	end
end

