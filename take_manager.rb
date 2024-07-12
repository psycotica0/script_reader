require_relative 'cursor'
require_relative 'session'

class Take
	POOR = 1
	OKAY = 2
	GOOD = 3
	TRSH = 4

	attr_reader :id, :selection, :start_time, :end_time
	attr_accessor :status

	def initialize(id, selection, start_time, end_time)
		@id = id
		@selection = selection
		@start_time = start_time
		@end_time = end_time
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
		@recording = RecordingTake.new(selection.dup.freeze)
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

	def new_take(start_time, end_time, selection)
		@takes << Take.new(@take_ids, selection, start_time, end_time)
		@take_ids += 1
	end

	def get_take(take_id)
		@takes.find { |t| t.id == take_id }
	end
end
