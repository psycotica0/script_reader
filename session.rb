require_relative 'session_meta'

class Session
	event :SetSync, :on_set_sync, "SS", :start_time do
		serial do |st|
			t(st)
		end
		deserial do |st, us|
			t(st,us)
		end
	end

	event :NewTake, :on_new_take, "NT", :start_time, :end_time, :selection_start_id, :selection_final_id do
		serial do |st, et, ssid, sfid|
			[*t(st), *t(et), ssid, sfid]
		end
		deserial do |st, su, et, eu, ssid, sfid|
			[*t(st, su), *t(et, eu), ssid, sfid]
		end
	end

	event :TakeStatus, :on_take_status, "TS", :take_id, :status do
		deserial do |ti, s|
			[ti.to_i, s.to_i]
		end
	end

	# I don't know why I care when the sync ended...
	# But it feels like I may use it at some point to compute... duration of
	# sync or something? Or "latest" session?
	# Feels like metadata I _could_ use, so I may as well capture
	event :ClearSync, :on_clear_sync, "CS", :at_time do
		serial do |at|
			t(at)
		end
		deserial do |at, au|
			t(at, au)
		end
	end

	event :FineTune, :on_fine_tune, "FT", :offset_ms do
		deserial do |om|
			[om.to_i]
		end
	end

	event :PlaybackFile, :on_playback_file, "PF", :filename

	def initialize(file)
		@file = file
		@file.sync = true

		begin
			@file.fsync
			@can_fsync = true
		rescue NotImplementedError
			# Not implemented happens if the OS doesn't support the feature
			@can_fsync = false
		rescue Errno::EINVAL
			# EInval happens if the file doesn't support the feature (notably /dev/null)
			@can_fsync = false
		end
	end

	def close
		@file.close
	end

	# This reads the file and processes the existing commands it finds
	def resume!
		@resumed = true
		@file.read.lines {|e| handle(e.strip) }
	end

	def handle(str)
		self.class.handle(str)
	end

	# This is specifically built so that I don't have two execution paths for
	# this critical stuff. I take the thing in, I serialize it, then deserialize
	# that and run the outcome.
	#
	# This is meant to make it much harder to fuckup my state management, or
	# have a serializer be silently broken or something.
	#
	# Basically, if it ever works, it should work exactly the same on resume.
	#
	# At least that's the hope...
	def <<(action)
		raise "Trying to add to unresumed stream!" unless @resumed
		
		str = action.serialize
		@file << str << "\n"
		# Not the most efficient, but make sure before moving on that the disk
		# definitely has our action
		@file.fsync if @can_fsync

		handle(str)
	end
end
