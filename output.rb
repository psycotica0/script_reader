class Output
	attr_accessor :audio_filename, :output_filename, :global_offset_ms

	def initialize
		@output_filename = "output.wav"
		@global_offset_ms = 0
		@play_queue = []
	end

	def process_takes(takes)
		return unless @audio_filename && File.readable?(@audio_filename)

		temp_dir = `mktemp -d`.strip

		begin
			segment_files = []

			takes.each_with_index do |take, index|
				start_pos = take.start_pos + (@global_offset_ms / 1000.0)
				end_pos = take.end_pos + (@global_offset_ms / 1000.0)
				segment_file = "#{temp_dir}/segment_#{index}.wav"
				segment_files << segment_file

				# Run sox to trim the segment
				`sox -q -V0 #{@audio_filename} #{segment_file} trim #{start_pos.to_s(3)} =#{end_pos.to_s(3)}`
			end

			# Concatenate all segments into the final output file
			sox_command = ["sox", "-q", "-V0"] + segment_files + [@output_filename]
			`#{sox_command.join(' ')}`
		ensure
			# Clean up temporary files
			FileUtils.rm_rf(temp_dir)
		end
	end

	def update_state
		return unless @playing_pid
		if Process.wait(@playing_pid, Process::WNOHANG)
			@playing_pid = nil
			play_next unless @play_queue.empty?
		end
	end

	def play_takes(takes)
		return unless @audio_filename && File.readable?(@audio_filename)

		stop_playing(true)
		@play_queue = takes
		play_next
	end

	def play_next
		return if @playing_pid
		take = @play_queue.shift
		return unless take

		start_pos = take.start_pos + (@global_offset_ms / 1000.0)
		end_pos = take.end_pos + (@global_offset_ms / 1000.0)
		@playing_pid = Process.spawn("play", "-V0", "-q", @audio_filename, "trim", start_pos.to_s(3), "=#{end_pos.to_s(3)}")
	end

	def stop_playing(blocking=false)
		@play_queue = []
		return unless @playing_pid

		Process.kill("TERM", @playing_pid)
		if blocking
			Process.wait(@playing_pid)
			@playing_pid = nil
		end
	end
end
