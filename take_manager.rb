require_relative 'cursor'
require_relative 'session'

class Take
	POOR = 1
	OKAY = 2
	GOOD = 3
	TRSH = 4

	attr_reader :id, :selection, :sync, :start_time, :end_time
	attr_accessor :status

	def initialize(id, selection, sync, start_time, end_time)
		@id = id
		@selection = selection
		@sync = sync
		@start_time = start_time
		@end_time = end_time
	end

	def <=>(other)
		rating = { TRSH => 0, POOR => 1, nil => 2, OKAY => 3, GOOD => 4}
		rating[status] <=> rating[other.status]
	end

	def start_pos
		@sync.offset_to(@start_time) if @sync
	end

	def end_pos
		@sync.offset_to(@end_time) if @sync
	end
end

class RecordingTake
	attr_reader :selection, :start_time

	def initialize(selection)
		@selection = selection
		@start_time = Time.now
	end

	def finish
		Session::NewTake.new(@start_time, Time.now, @selection.start.id, @selection.final.id)
	end
end

class TakeManager
	attr_reader :recording

	def initialize
		@takes = []
		@take_ids = 1
	end
	
	def start_recording(selection)
		@recording = RecordingTake.new(selection)
	end

	def cancel_recording
		@recording = nil
	end

	def stop_recording
		return unless @recording
		r = @recording.finish
		@recording = nil
		r
	end

	def find_takes(selection)
		@takes.select { |i| i.selection.contains?(selection) }
	end

	def new_take(sync, start_time, end_time, selection)
		@takes << Take.new(@take_ids, selection, sync, start_time, end_time)
		@take_ids += 1
	end

	def get_take(take_id)
		@takes.find { |t| t.id == take_id }
	end

	def most_recent_take
		@takes.last
	end
end
