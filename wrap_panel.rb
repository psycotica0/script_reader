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
			pad << " " if idx > 0 and pad.curx < width
			s.layout(pad, width, margin)
		end
		pad.clrtoeol
		pad.setpos(pad.cury + 1, 0)
	end
end

class Sentence
	def layout(pad, width, margin)
		@spans.each do |s|
			s.layout(pad, width, margin)
		end
	end
end

class Span
	def attrs
		Curses::A_NORMAL
	end

	def layout(pad, width, margin)
		to_s.scan(/.+?(?=\s|$)/).each do |word|
			if pad.curx + word.length > width
				pad.setpos(pad.cury + 1, margin)
				word.lstrip!
				pad.clrtoeol
			end

			# The last row lines up perfectly with the end and wrapped
			if pad.curx < margin
				pad.setpos(pad.cury, margin)
				word.lstrip!
			end

			pad.attron(attrs) do
				pad << word
			end
		end
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
	attr_reader :pad

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

