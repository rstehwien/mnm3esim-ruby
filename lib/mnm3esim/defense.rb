module MnM3eSim
	class Defense < MnM3eBase
		attr_accessor :value
		attr_accessor :save
		attr_accessor :impervious # any attack difficulty less is ignored

		def self.defaults
			{
			:value => 10,
			:save => 10,
			:impervious => nil
	    	}
	    end

		def initialize(args={})
		    Defense::defaults.merge(args).each {|k,v| send("#{k}=",v)}
		end
	end
end