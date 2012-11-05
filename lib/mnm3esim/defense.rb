module MnM3eSim
	ResistResult = SuperStruct.new(:d20, :roll, :degree, :stress, :status)

	class Defense < ModifiableStructData
		attr_accessor_modifiable :value,
			:save,
			:impervious # any attack difficulty less is ignored

		def self.defaults
			{
			:value => 10,
			:save => 10,
			:impervious => nil
	    	}
	    end

		def initialize(args={})
			super(Defense::defaults.merge(args))
		end

		def resist_hit(hit, stress)
			# basic full resist
			resist = ResistResult.new({
				:d20=>nil,
				:roll=>nil,
				:degree=>4,
				:stress=>0,
				:status=>nil
				})

			# bail if impervious to this attack
			if self.impervious != nil then
				bounce = self.impervious - hit.attack.penetrating
				return resist if bounce >= hit.damage_impervious
			end

			# Always roll vs Damage+10 to determin status and stress
			# The degree will be the status inflicted
			# Stress caused if degree <= 1 (equivalent to Damage+15)
			resist.d20 = roll_d20
			resist.roll = resist.d20 + self.save - stress
			resist.degree = check_degree(hit.damage + 10, resist.roll)

			if resist.d20 == 20 then
				resist.degree = resist.degree < 1 ? 1 : resist.degree + 1
			end

			# if stress is caused, it is for a status effect of -1 and higher (equivalent to save of rank+15)
			resist.stress = 1 if hit.attack.is_cause_stress and resist.degree <= 1

			resist.status = hit.attack.status_by_resist_degree(resist.degree)

			return resist
		end
	end
end