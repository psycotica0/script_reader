class ID
	attr_reader :line_num, :sentence_num

	def initialize(l, s)
		@line_num = l
		@sentence_num = s
	end

	def to_s
		"%03d.%02d" % [@line_num, @sentence_num]
	end
end

class Parser
	attr_reader :chunks

	def initialize(str)
		@chunks = []
		@codeblock = nil
		str.lines.each.with_index(1) do |line, line_num|
			line.strip!
			if @codeblock && line.start_with?("```")
				@codeblock << line
				@chunks << @codeblock
				@codeblock = nil
			elsif @codeblock
				@codeblock << line
			elsif line.empty?
				@chunks << BlankLine.new(line_num)
			elsif line.start_with?("```")
				@codeblock = CodeBlock.new(line_num)
				@codeblock << line
			else
				@chunks << Line.new(line_num, line)
			end
		end
	end
end

class BlankLine
	def initialize(idx)
		@idx = idx
	end

	def to_s
		""
	end

	def line_num
		@idx
	end
end

class Line
	def initialize(idx, str)
		@idx = idx
		@sents = str.split(/(?<!\.\.)(?<=[\.!?])(?=\s|$)/).each_with_index.map do |sent, sub_idx|
			Sentence.new(ID.new(idx, sub_idx), sent.strip)
		end
	end

	def to_s
		@str
	end

	def line_num
		@idx
	end
end

class Sentence
	attr_reader :id

	def initialize(id, str)
		@id = id
		# Split on stuff surrounded in _ or * (separated by spaces), and leave the rest
		@spans = str.scan(/(?<=\W)_[^_]+_(?=\W)|(?<=\W)\*[^\*]+\*(?=\W)|.+?(?:\W(?=_|\*)|$)/).map do |s|
			if s.start_with?("*")
				Strong.new(s)
			elsif s.start_with?("_")
				Emph.new(s)
			else
				Span.new(s)
			end
		end
	end
end

class Span
	def initialize(s)
		@s = s
	end

	def to_s
		@s
	end
end

class Strong < Span
end

class Emph < Span
end

class CodeBlock
	def initialize(starting_line_num)
		@line_num = starting_line_num
		@lines = []
	end

	def <<(line)
		@lines << line
	end
end
