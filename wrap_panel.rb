require 'curses'
require_relative 'parser'

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
			space = (idx > 0 and pad.curx < width) ? InterSentenceSpace.new : nil
			s.layout(pad, width, margin, space)
		end
		pad.clrtoeol
		pad.setpos(pad.cury + 1, 0)
	end
end

class InterSentenceSpace
	def layout(pad)
		# Capture for redraws
		@pad = pad
		@x, @y = pad.curx, pad.cury
		draw
	end

	def draw
		@pad.attron(@active ? Curses::A_STANDOUT : 0) do
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
	def layout(pad, width, margin, pre_space)
		@pre_space = pre_space
		@pre_space.layout(pad) if @pre_space

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
		@active ? Curses::A_STANDOUT : 0
	end

	def activate
		@active = true
	end

	def deactivate
		@active = false
	end
end

class Emph
	def attrs
		# Italic: I stole this from the source
		-2147483648
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
	attr_accessor :default_style, :active_style
	attr_reader :pad, :height

	def initialize(height, width, top, left, p)
		@height = height
		@width = width
		@left = left
		@top = top
		@parse = p
		@pad = Curses::Pad.new(5000, width)
		@scroll_pos = 0
	end

	def layout
		@parse.layout(@pad, @width)
	end

	def refresh
		@pad.refresh(@scroll_pos, 0, @top, @left, @top + @height - 1, @left + @width)
	end

	def scroll(n)
		@scroll_pos += n

		@scroll_pos = 0 if @scroll_pos < 0
	end
end

