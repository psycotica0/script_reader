require_relative 'cursor'

class Take
	POOR = 1
	OKAY = 2
	GOOD = 3
	TRSH = 4

	attr_reader :selection, :start_time, :end_time
	attr_accessor :status

	def initialize(selection, start_time, end_time)
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
		Take.new(@selection, @start_time, Time.now)
	end
end

class TakeManager
	attr_reader :recording

	def initialize
		@takes = []
	end
	
	def start_recording(selection)
		@recording = RecordingTake.new(selection.dup.freeze)
	end

	def cancel_recording
		@recording = nil
	end

	def stop_recording
		return unless @recording
		@takes << @recording.finish
		@recording = nil
	end

	def find_takes(selection)
		@takes.select { |i| i.selection.contains?(selection) }
	end
end
