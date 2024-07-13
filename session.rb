class Session
	SetSync = Struct.new(:start_time) do
		def serialize
			["SS", start_time.to_i].join(":")
		end

		def self.deserialize(str)
			code, start_str = str.split(":")
			return unless code == "SS"

			new(Time.at(start_str.to_i))
		end
	end

	NewTake = Struct.new(:start_time, :end_time, :selection_start_id, :selection_final_id) do
		def serialize
			["NT", start_time.to_i, end_time.to_i, selection_start_id, selection_final_id].join(":")
		end

		def self.deserialize(str)
			code, start_str, end_str, start_id, end_id = str.split(":")
			return unless code == "NT"

			new(Time.at(start_str.to_i), Time.at(end_str.to_i), start_id, end_id)
		end
	end

	TakeStatus = Struct.new(:take_id, :status) do
		def serialize
			["TS", take_id, status].join(":")
		end

		def self.deserialize(str)
			code, take_id, status = str.split(":")
			return unless code == "TS"

			new(take_id.to_i, status.to_i)
		end
	end

	# I don't know why I care when the sync ended...
	# But it feels like I may use it at some point to compute... duration of
	# sync or something? Or "latest" session?
	# Feels like metadata I _could_ use, so I may as well capture
	ClearSync = Struct.new(:at_time) do
		def serialize
			["CS", at_time.to_i].join(":")
		end

		def self.deserialize(str)
			code, at_str = str.split(":")
			return unless code == "CS"

			new(Time.at(at_str.to_i))
		end
	end

	def initialize(file)
		@file = file
		@file.sync = true
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
		ss = SetSync.deserialize(str)
		return @ss_handler.call(ss) if ss

		nt = NewTake.deserialize(str)
		return @nt_handler.call(nt) if nt

		ts = TakeStatus.deserialize(str)
		return @ts_handler.call(ts) if ts

		cs = ClearSync.deserialize(str)
		return @cs_handler.call(cs) if cs
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
		@file.fsync

		handle(str)
	end

	def on_set_sync(&block)
		@ss_handler = block
	end

	def on_new_take(&block)
		@nt_handler = block
	end

	def on_take_status(&block)
		@ts_handler = block
	end

	def on_clear_sync(&block)
		@cs_handler = block
	end
end
