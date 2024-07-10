require_relative 'parser'

class Parser
	def selection
		sel = nil
		@chunks.each do |chunk|
			s = chunk.selection
			next unless s
			
			if sel
				sel.join!(s)
			else
				sel = s
			end
		end

		sel
	end
end

class CodeBlock
	def selection
		# I don't want to select code blocks, so just skip them
		nil
	end
end

class BlankLine
	def selection
		# I don't want to select blank lines, so just skip them
		nil
	end
end

class Line
	def selection
		sel = nil
		@sents.each do |sent|
			if sel
				sel.join!(sent.selection)
			else
				sel = sent.selection
			end
		end

		sel
	end
end

class Sentence
	def selection
		cur = Cursor.new(self)
		sel = Selection.new(cur, cur)

		if @pre_space
			sc = Cursor.new(@pre_space, true)
			sel = Selection.new(sc, sc).join!(sel)
		end

		sel
	end
end

class Cursor
	attr_accessor :item, :true_next, :true_prev

	def initialize(item, skip = false)
		@item = item
		@skip = skip
	end

	def skip?
		@skip
	end

	def next=(v)
		@true_next = v
	end

	def prev=(v)
		@true_prev = v
	end

	def next
		return nil unless @true_next
		return @true_next unless @true_next.skip?

		@true_next.next
	end

	def prev
		return nil unless @true_prev
		return @true_prev unless @true_prev.skip?

		@true_prev.prev
	end

	def has_next?
		!!@true_next
	end

	def has_prev?
		!!@true_prev
	end

	# This is inclusive of the final
	def until(final, &block)
		cur = self
		e = Enumerator.new do |i|
			loop do
				i << cur.item
				break if cur == final
				break unless cur.has_next?
				cur = cur.true_next
			end
		end

		if block
			e.each(&block)
		else
			e
		end
	end

	def id
		item.id
	end
end

class Selection
	attr_reader :start, :final

	def initialize(start, final)
		@start = start
		@final = final
	end

	def move_down
		if final.has_next?
			deactivate
			@start = final.next
			@final = start
			activate
		end
	end

	def move_up
		if start.has_prev?
			deactivate
			@start = start.prev
			@final = start
			activate
		end
	end

	def spread_down
		if final.has_next?
			@final.until(final.next) do |s|
				s.activate
				s.redraw
			end
			@final = @final.next
		end
	end

	def spread_up
		if start.has_prev?
			@start.prev.until(@start) do |s|
				s.activate
				s.redraw
			end
			@start = @start.prev
		end
	end

	def join!(second)
		@final.next = second.start
		second.start.prev = @final
		@final = second.final
		self
	end

	def activate
		@start.until(@final) do |s|
			s.activate
			s.redraw
		end
	end

	def deactivate
		@start.until(@final) do |s|
			s.deactivate
			s.redraw
		end
	end

	def to_start!
		@final = @start
	end

	def top
		@start.item.top
	end

	def bottom
		@final.item.bottom
	end

	def contains?(other)
		other.start.id.between?(start.id, final.id) && other.final.id.between?(start.id, final.id)
	end

	def ===(other)
		contains?(other)
	end

	def ==(other)
		start.id == other.start.id && final.id == other.final.id
	end
end
