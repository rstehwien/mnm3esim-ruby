module MnM3eSim
	class Defense < ModifiableStructData
		DATA_STRUCT = Struct.new(
			:value,
			:save,
			:impervious # any attack difficulty less is ignored
		)

		def self.defaults
			{
			:value => 10,
			:save => 10,
			:impervious => nil
	    	}
	    end

		def initialize(args={})
			puts "test"
			@data = DATA_STRUCT.new
			super(Defense::defaults.merge(args))
		end
	end
end