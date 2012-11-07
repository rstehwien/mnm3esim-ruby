module MnM3eSim
	CharacterEffect = SuperStruct.new(:attack, :defense, :degree)

	class Character < ModifiableStructData
		attr_accessor_modifiable :name,
			:attack,
			:defense,
			:initiative,
			:actions, # one of :full, :partial, :none
			:is_controlled,
			:initiative_value

		# stress is equivalent to the "cumulative -1 to resistance"
		attr_accessor  :stress, :status, :effects, :status_degree

		def self.defaults
			{
	    	:name => "Character",
			:attack => nil,
			:defense => nil,
			:initiative => 0,
			:actions => :full,
			:is_controlled => false
		    }
		end

		def initialize(args={})
		    super(Character::defaults.merge(args))
		    init_combat
		end

		def init_combat
			self.initiative_value = roll_d20(self.initiative)
			self.stress = 0
			self.actions = :full

			self.effects = {}
			update_status
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

			# bail if we took no stress or status
			return if resist.stress < 1 and (resist.status == nil or resist.status.degree < 1)

			self.stress += resist.stress
			#puts "#{self.name} apply_damage resist_degree: #{resist.degree} resist_stress: #{resist.stress} total_stress: #{self.stress}"; sleep 1

			return if resist.status == nil or resist.status.degree < 1

			cur_degree = (self.effects.has_key? hit.attack) ? effects[hit.attack].degree : 0
			new_degree = Status.degree(resist.status)
			#puts "#{self.name} apply_damage damage_degree: #{new_degree}"; sleep 1

			# cumulative attacks add their degrees
			# NOTE: damage sets the cumulative degree to [2] which means another staggered will add 2 to the degree, but it works out right
			cumulative_statuses = hit.attack.cumulative_statuses
			if cumulative_statuses.include?(cur_degree) and cumulative_statuses.include?(new_degree) then
				new_degree += cur_degree
			end

			# non-cumulative only replaces if new degree is better
			if new_degree > cur_degree then
				#puts "#{self.name} apply_damage cur_degree: #{cur_degree} new_degree: #{new_degree}"; sleep 1
				self.effects[hit.attack] = CharacterEffect.new(hit.attack, resist.defense, new_degree)
				update_status
			end
		end

		def update_status
			s = self.effects.values.inject([]){|a,effect| 
				a.push(effect.attack.status_by_degree(effect.degree).key)
			}

			statuses = Status.combined_status(s)
			self.status = statuses[:statuses]
			self.status_degree = statuses[:degree]

			#puts self.status.inject([]){|a,(k,v)| a.push(k)}.to_yaml

			#puts "#{self.name} update_status status_degree: #{self.status_degree} total_stress: #{self.stress}"; sleep 1

			# Handle the modifiers
			self.clear_modifiers
			self.attack.clear_modifiers if self.attack != nil
			self.defense.clear_modifiers if self.defense != nil

			statuses[:modifiers].each do |m|
				groups = m.group == (Array(m.group).include? :ALL) ? [:character, :attack, :defense] : Array(m.group)
				self.add_modifier(m.property, m.modifier) if groups.include? :character
				self.attack.add_modifier(m.property, m.modifier) if self.attack != nil and groups.include? :attack
				self.defense.add_modifier(m.property, m.modifier) if self.defense != nil and groups.include? :defense
			end
		end

		def end_round_recovery
			changed = false
			self.effects.values.each do |effect|
				# next if no recovery check allowed or needed
				next if !effect.attack.is_status_recovery or effect.degree < 1 or effect.degree > 2

				resistance = check_degree(effect.attack.rank + 10, + roll_d20(effect.defense.save))

				# if resistance sucessful, lower the status by one
				if resistance > 0
					changed = true
					effect.degree = 0
					#puts "#{self.name} RECOVERED"; sleep 1
				# if failed and progressive, increase status by one
				elsif effect.attack.is_progressive
					changed = true
					effect.degree += 1
					#puts "#{self.name} PROGRESSIVE"; sleep 1
				end
			end

			if changed then
				self.effects.delete_if {|k,v| v.degree < 1}
				update_status
			end
		end
	end
end