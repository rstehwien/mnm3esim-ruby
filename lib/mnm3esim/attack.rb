module MnM3eSim
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
			:is_multiattack
		)

		attr_accessor :statuses

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
			@statuses = value.inject([]) {|a,v| (v.kind_of? Status) ? a.push(v) : a.push(Status::STATUSES[v]) }
		end

		def roll_attack(value)
			damage_impervious = self.rank
			damage = self.rank

			return {:degree => 1, :damage=>damage, :damage_impervious=>damage_impervious} if self.is_perception_attack

			hit_roll = roll_d20

			# roll of 1 automatically misses
			return {:degree=>-1, :damage=>0, :damage_impervious=>0} if hit_roll == 1

			hit_degree = check_degree(value+10, hit_roll + self.bonus)

			# crit if you hit and got the min_crit or better
			is_crit = (hit_degree > 0 and hit_roll >= self.min_crit)

			# guaranteed hit if you rolled a 20
			hit_degree = 1 if (hit_roll == 20 and hit_degree < 1)

			# if hit degree < 0 we have missed
			return {:degree=>hit_degree, :damage=>0, :damage_impervious=>0} if hit_degree < 0

			# crit bumps the damage and impervious up by 5
			if is_crit
				damage += 5
				damage_impervious += 5
			end

			# multi-attack bumps up by 5 or 2 but not penetrating
			if self.is_multiattack and hit_degree > 1 then
				damage += hit_degree >= 3 ? 5 : 2
			end

			{:degree=>hit_degree, :damage=>damage, :damage_impervious=>damage_impervious}
		end
	end

	AttackResult = Struct.new(:degree, :damage, :damage_impervious, :attack)
	class AttackResult
		attr_accessor :degree
		attr_accessor :damage
		attr_accessor :damage_impervious
		attr_accessor :attack
		def initialize(args={})
		   {
		   	:degree=>-1, #miss
		   	:damage=>nil, 
		   	:damage_impervious=>nil, 
		   	:attack=>nil
		   }.merge(args).each {|k,v| send("#{k}=",v)}
		end
	end
end