module MnM3eSim
	AttackResult = SuperStruct.new(:attack, :damage, :damage_impervious, :d20, :roll, :is_crit, :degree)

	class Attack < ModifiableStructData
		DATA_STRUCT = Struct.new(
			:bonus,
			:rank,
			:penetrating,
			:is_cause_stress,
			:is_perception_attack,
			:min_crit,
			:cumulative_statuses, # array of statuses that cause bump to next.  either [], [2], or [1,2]
			:is_status_recovery,
			:is_progressive,
			:is_multiattack,
			:statuses
		)

		def self.defaults_damage
			{
			:bonus => 10,
			:rank => 10,
			:penetrating => 0,
			:is_cause_stress => true,
			:is_perception_attack => false,
			:min_crit => 20,
			:cumulative_statuses => [2],
			:is_status_recovery => false,
			:is_progressive => false,
			:is_multiattack => false,
			:statuses=>[:dazed,:staggered,:incapacitated]
			}
		end

		def self.defaults_affliction
			{
			:bonus => 10,
			:rank => 10,
			:penetrating => 0,
			:is_cause_stress => false,
			:is_perception_attack => false,
			:min_crit => 20,
			:cumulative_statuses => [],
			:is_status_recovery => true,
			:is_progressive => false,
			:is_multiattack => false,
			:statuses=>[:dazed,:staggered,:incapacitated]
			}
		end

		def self.defaults
			self.defaults_damage
		end

		def self.create_damage(args={})
			Attack.new(Attack::defaults_damage.merge(args))
		end
		def self.create_affliction(args={})
			Attack.new(Attack::defaults_affliction.merge(args))
		end

		def initialize(args={})
			@data = DATA_STRUCT.new
		    super(Attack::defaults.merge(args))
		end

		def statuses=(value)
			@data.statuses = value.inject([]) {|a,v| (v.kind_of? Status) ? a.push(v) : a.push(Status::STATUSES[v]) }
		end

		def status_by_resist_degree(degree)
			return Status::STATUSES[:none] if degree > 0

			status_by_degree(degree.abs)
		end

		def status_by_degree(degree)
			return Status::STATUSES[:none] if degree < 1

			self.statuses[[degree, self.statuses.length].min-1]
		end


		def attack_defense(defense)
			# create basic miss
			hit = AttackResult.new({
				:attack=>self, 
				:damage=>self.rank, 
				:damage_impervious=>self.rank, 
				:d20=>nil,
				:roll=>nil,
				:is_crit=>false,
				:degree=>-1, 
				})

			# if perception attack; return a basic hit
			if self.is_perception_attack then
				hit.degree = 1
				return hit
			end

			hit.d20 = roll_d20
			hit.roll = hit.d20 + self.bonus

			# roll of 1 automatically misses
			if hit.d20 == 1 then
				hit.degree = -1
				return hit
			end

			hit.degree = check_degree(defense.value+10, hit.roll)

			# crit if you hit and got the min_crit or better
			hit.is_crit = (hit.degree > 0 and hit.d20 >= self.min_crit)

			# guaranteed hit if you rolled a 20
			hit.degree = 1 if (hit.d20 == 20 and hit.degree < 1)

			# if hit degree < 0 we have missed
			return hit if hit.degree < 0

			# crit bumps the damage and impervious up by 5
			if hit.is_crit
				hit.damage += 5
				hit.damage_impervious += 5
			end

			# multi-attack bumps up by 5 or 2 but not damage_impervious
			if self.is_multiattack and hit.degree > 1 then
				hit.damage += hit.degree >= 3 ? 5 : 2
			end

			return hit
		end
	end
end