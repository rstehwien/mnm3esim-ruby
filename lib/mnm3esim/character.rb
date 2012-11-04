module MnM3eSim
	class Character < ModifiableStructData
		DATA_STRUCT = Struct.new(
			:name,
			:attack,
			:defense,
			:initiative,
			:actions, # one of :full, :partial, :none
			:is_controlled,
			:initiative_value,
			:stress, # stress is equivalent to the "cumulative -1 to resistance"
			:status
		)

		def self.defaults
			{
	    	:name => "Character",
			:attack => nil,
			:defense => nil,
			:initiative => 0,
			:actions => :full,
			:is_controlled => false,
			:initiative_value => 0,
			:stress => 0,
			:status => Status::STATUSES[:none]
		    }
		end

		def initialize(args={})
			@data = DATA_STRUCT.new
		    super(Character::defaults.merge(args))
		end

		def init_combat
			self.stress = 0
			set_status(:none)
			self.actions = :full
			self.initiative_value = roll_d20(self.initiative)
		end

		def attack_target(target)
			# bail if attack or defense is nil
			return if self.attack == nil or target.defense == nil

			result = self.attack.roll_attack(target.defense.value)

			# apply the damage if needed
			if result[:degree] > 0 then
				target.apply_damage(self.attack, result[:damage])
			end
		end

		def apply_damage(attack, damage)
			# bail if impervious to this attack
			if self.defense.impervious != nil then
				impervious = self.defense.impervious - attack.penetrating
				return if impervious >= damage[:damage_impervious]
			end

			# Always roll vs Damage+10 to determin status and stress
			# The degree will be the status inflicted
			# Stress caused if degree <= 1 (equivalent to Damage+15)
			save_roll = roll_d20
			resistance = save_roll + self.defense.save - self.stress
			degree = check_degree(damage + 10, resistance)

			if save_roll == 20 then
				degree = degree < 1 ? 1 : degree + 1
			end


			# if stress is caused, it is for a status effect of -1 and higher (equivalent to save of rank+15)
			self.stress += 1 if attack.is_cause_stress and degree <= 1

			status_degree = degree > 0 ? nil : [degree.abs, attack.statuses.length].min
			update_status(status_degree, attack)
		end

		def update_status(new_degree, attack)
			return if new_degree == nil or new_degree < 1

			cur_degree = self.status.degree

			# cumulative attacks add their degrees
			# NOTE: damage sets the cumulative degree to [2] which means another staggered will add 2 to the degree, but it works out right
			if attack.cumulative_statuses.include?(cur_degree) and attack.cumulative_statuses.include?(new_degree) then
				set_status(cur_degree+new_degree, attack)
			# non-cumulative only replaces if new degree is better
			elsif new_degree > cur_degree
				set_status(new_degree, attack)
			end
		end

		def set_status(sv, attack=nil)
			return if sv == nil

			if sv.is_a? Symbol then
				self.status = Status::STATUSES[sv]
			elsif sv.is_a? Fixnum and sv < 1 then
				self.status = Status::STATUSES[:none]
			elsif attack != nil and sv.is_a? Fixnum then
				self.status = attack.statuses[([sv, attack.statuses.length].min)-1]
			else
				self.status = nil
			end
			if self.status == nil then
				puts sv.class.name
				puts "sv = #{sv}"
				puts attack.to_yaml
				throw "BAD STATUS"
			end
		end

		def end_round_recovery(attack)
			# bail if no recovery check needed: no attack, no recovery
			return if attack == nil or !attack.is_status_recovery or self.defense == nil
			
			status_degree = self.status.degree
			# bail if nothing to recover or if you can't recover (status too high)
			return if status_degree < 1 or status_degree > 2
			
			resistance = check_degree(attack.rank + 10, self.defense.save + roll_d20)
			# if resistance sucessful, lower the status by one
			if resistance > 0
				status_degree = 0
			# if failed and progressive, increase status by one
			elsif attack.is_progressive
				status_degree += 1
			end

			set_status(status_degree, attack)
		end
	end
end