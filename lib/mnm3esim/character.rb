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

			target.apply_hit(self.attack.attack_defense(target.defense))
		end

		def apply_hit(hit)
			# bail if missed
			return if hit.degree < 0

			resist = self.defense.resist_hit(hit, self.stress)
			self.stress += resist.stress

			return if resist.status == nil or resist.status.degree < 1

			cur_degree = self.status.degree
			new_degree = resist.status.degree
			cumulative_statuses = hit.attack.cumulative_statuses

			# cumulative attacks add their degrees
			# NOTE: damage sets the cumulative degree to [2] which means another staggered will add 2 to the degree, but it works out right
			if cumulative_statuses.include?(cur_degree) and cumulative_statuses.include?(new_degree) then
				new_degree += cur_degree
			end

			# non-cumulative only replaces if new degree is better
			if new_degree > cur_degree then
				set_status(hit.attack.status_by_degree(new_degree), hit.attack)
			end
		end

		def set_status(sv, attack=nil)
			return if sv == nil

			if sv.is_a? Symbol then
				self.status = Status::STATUSES[sv]
			elsif sv.is_a? Status then
				self.status = sv
			elsif sv.is_a? Fixnum and sv < 1 then
				self.status = Status::STATUSES[:none]
			elsif attack != nil and sv.is_a? Fixnum then
				self.status = attack.status_by_degree(sv)
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