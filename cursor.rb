require_relative 'parser'

class Selection
end

module UnsafeCursorMutation
	refine Selection do
		# XXX: By modifying the cursors it means each of the input selections end
		# up kinda mutated / broken.
		# It looks immutable on the outside, and the new one functions immutably,
		# but again, the inputs are consumed in the process!
		# If you weren't planning on using them again, though, then this is fine.
		def +(second)
			@final.next = second.start
			second.start.prev = @final

			Selection.new(@start, second.final)
		end
	end
end

class Parser
	using UnsafeCursorMutation

	def full_selection
		# Apparently I can't trust that `sum` will use my definition of `+`
		@sel ||= @chunks.map(&:selection).compact.reduce(&:+)
	end

	# This returns a new selection that goes between (and including) the two
	# sentences given
	def get_selection(start_id, end_id)
		start = nil
		full_selection.start.until_cur(full_selection.final).each do |s|
			if s.id.to_s == start_id
				start = s
			end
			# It can be both start and end
			if s.id.to_s == end_id
				raise "Invalid Range: End before Start #{start_id} #{end_id}" unless start
				return Selection.new(start, s)
			end
		end

		raise "Invalid IDs #{start_id} #{end_id}"
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
	using UnsafeCursorMutation

	def selection
		@sents.map(&:selection).reduce(&:+)
	end
end

class Sentence
	using UnsafeCursorMutation

	def selection
		cur = Cursor.new(self)
		sel = Selection.new(cur, cur)

		if @pre_space
			sc = Cursor.new(@pre_space, true)
			sel = Selection.new(sc, sc) + sel
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
	def until_cur(final, &block)
		cur = self
		e = Enumerator.new do |i|
			loop do
				i << cur
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

	def until(final, &block)
		until_cur(final).map(&:item).each(&block)
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
		freeze
	end

	def move_down
		if final.has_next?
			deactivate
			Selection.new(final.next, final.next).tap(&:activate)
		else
			self
		end
	end

	def move_up
		if start.has_prev?
			deactivate
			Selection.new(start.prev, start.prev).tap(&:activate)
		else
			self
		end
	end

	def spread_down
		if final.has_next?
			@final.until(final.next) do |s|
				s.activate
				s.redraw
			end
			Selection.new(@start, @final.next)
		else
			self
		end
	end

	def spread_up
		if start.has_prev?
			@start.prev.until(@start) do |s|
				s.activate
				s.redraw
			end
			Selection.new(@start.prev, @final)
		else
			self
		end
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

	def at_start
		Selection.new(@start, @start)
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
