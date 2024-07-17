require 'set'

class ChoiceExport
	attr_reader :takes

	def self.of(selection, take_manager)
		dumped = Set.new
		chosen = selection.start.until(selection.final).flat_map do |s|
			ts = take_manager.find_takes(s.id)

			best_rating = ts.max
			best_takes = ts.select { |t| t.status == best_rating.status }

			best_takes.select { |t| dumped.add?(t.id) }
		end

		new(chosen)
	end

	def initialize(chosen_takes)
		@takes = chosen_takes
	end

	def write(file)
		@takes.each do |t|
			file << "%03d %s %s\n" % [t.id, t.sync.offset_to(t.start_time).to_s(3), t.sync.offset_to(t.end_time).to_s(3)]
		end
	end

	def write_label_file(file, global_offset_ms)
		@takes.each do |take|
			start_pos = take.start_pos + (global_offset_ms / 1000.0)
			end_pos = take.end_pos + (global_offset_ms / 1000.0)
			file << "%f\t%f\t%03d\n" % [start_pos, end_pos, take.id]
		end
	end
end
