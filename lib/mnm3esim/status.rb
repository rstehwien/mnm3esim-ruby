module MnM3eSim
	StatusModifier = SuperStruct.new(:group, :property, :modifier, :description)

	class Status < SuperStruct.new(:key, :degree, :modifiers, :recovery, :replace)
		# :modifiers => array of modifiers in form of one of the following
		# nil => no modifiers this program can express currently
		# [symbolN,modifierN] => an array of any number of symbols or modifiers
		# symbol is another status
		# mofifier is an array of corresponding to StatusModifier.  
		#  :group => :ALL means all groups, can be array or individual
		#  :property => :ALL means all properties, can be array or individual

		# :recovery => true if automatically recovered, actual recovery varies but this is simplified for sim

		STATUSES={}

		def initialize(*args, &block)
			super(*args, &block)
			raise ArgumentError, "Status not unique #{self.key}" if STATUSES.has_key? self.key
			STATUSES[self.key] = self
		end

		def self.get_status(value)
			if value.is_a? Status then
				return value
			elsif (value.is_a? String) or (value.is_a? Symbol) then
				s = STATUSES[value.to_sym]
				raise ArgumentError, "Invalid status #{s}" if s == nil
				return s
			else
				return nil
			end
		end

		def self.combined_status(value)
			statuses = do_expand_statuses(value)

			modifiers = []
			degrees = []
			statuses.each do |k,status|
				degrees.push(status.degree)
				Array(status.modifiers).each do |m|
					modifiers.push(StatusModifier.new(*m)) if m.is_a? Array
				end
			end
			max = degrees.length > 0 ? degrees.max : 0		

			{:statuses => statuses, :modifiers => modifiers, :degree => max}
		end

		def self.expand_statuses(value)
			combined_status(value)[:statuses]
		end

		def self.all_modifiers(value)
			combined_status(value)[:modifiers]
		end

		def self.degree(value)
			combined_status(value)[:degree]
		end

		protected
		def self.do_expand_statuses(value)
			value = value.values if value.kind_of? Hash
			result = {}
			Array(value).each do |v| 
				status = get_status(v)
				next if status == nil or result.has_key? status.key

				result[status.key] = status

				result = result.merge(do_expand_statuses(status.modifiers)) if status.modifiers.is_a? Array
			end

			# remove any we replace
			replacing = result.inject([]) {|a,(k,status)| a.push(*Array(status.replace))}
			result.delete_if {|k,v| replacing.include? k}

			result[:normal] = STATUSES[:normal] if result.length < 1
			result.delete(:normal) if result.length > 1

			result
		end

	end

	# ALL STANDARD STATUSES
	[
		# NORMAL 
		{:key => :normal, :degree => 0, :modifiers => nil, :recovery => false, :replace => nil}, 

		########################################
		# BASIC CONDITIONS
		########################################
		# COMPELLED: action chosen by controller, limited to free actions and a single standard action per turn
		{
			:key => :compelled, 
			:degree => 2, 
			:modifiers => [:action_partial, :actions_controlled], 
			:recovery => false
		},

		# CONTROLLED: full actions chosen by controller
		{
			:key => :controlled, 
			:degree => 3, 
			:modifiers => [:actions_controlled], 
			:recovery => false,
			:replace => :compelled
		},
		
		# DAZED: limited to free actions and a single standard action per turn
		{
			:key => :dazed, 
			:degree => 1, 
			:modifiers => [:action_partial], 
			:recovery => false
		}, 
		
		# DEBILITATED: The character has one or more abilities lowered below –5.
		{
			:key => :debilitated, 
			:degree => 3, 
			:modifiers => [:action_none], 
			:recovery => false,
			:replace => [:disabled, :weakened]
		},

		# DEFENSELESS: defense = 0
		{
			:key => :defenseless, 
			:degree => 2, 
			:modifiers =>  [[:defense, :value, lambda{|x|0}, "defenseless"]], 
			:recovery => false,
			:replace => :vulnerable
		},

		# DISABLED: checks - 5 
		{
			:key => :disabled, 
			:degree => 2, 
			:modifiers =>  [[:ALL, :roll_d20, lambda{|x| x - 5}, "disabled; -5 to checks"]], 
			:recovery => false,
			:replace => :impaired
		},

		# FATIGUED: hindered, recover in an hour
		{
			:key => :fatigued, 
			:degree => 1, 
			:modifiers => [:hindered], 
			:recovery => false
		}, 

		# HINDERED: speed - 1 (half speed)
		{
			:key => 
			:hindered, :degree => 1, 
			:modifiers => [[:character, :speed, lambda{|x| x - 1}, "hindered: -1 speed"]], 
			:recovery => false
		},
		
		# IMMOBLE:
		{
			:key => :immobile, 
			:degree => 2, 
			:modifiers =>  [[:character, :speed, lambda{|x| nil}, "immoble: no speed"]], 
			:recovery => false,
			:replace => :hindered
		},
		
		# IMPAIRED: checks - 2 
		{
			:key => :impaired, 
			:degree => 1, 
			:modifiers => [[:ALL, :roll_d20, lambda{|x| x - 2}, "impaired; -2 to checks"]], 
			:recovery => false
		},

		# STUNNED:
		{
			:key => :stunned, 
			:degree => 2, 
			:modifiers => [:action_none], 
			:recovery => false,
			:replace => :dazed
		},

		# TRANSFORMED: becomes something else
		{
			:key => :transformed, 
			:degree => 3, 
			:modifiers => [:action_none], 
			:recovery => false
		},
		
		# UNAWARE:unaware of surroundings and unable to act on it
		{
			:key => :unaware, 
			:degree => 3, 
			:modifiers => [:action_none], 
			:recovery => false
		},
		
		# VULNERABLE: defense.value/2 [RU]
		{
			:key => :vulnerable, 
			:degree => 1, 
			:modifiers => [[:defense, :value, lambda{|x| (x.to_f/2).ceil}, "vulnerable: 1/2 defense"]], 
			:recovery => false
		},
		
		# WEAKENED: trait is lowered
		{
			:key => :weakened, 
			:degree => 1, 
			:modifiers => nil, 
			:recovery => false
		},
		
		########################################
		# COMBINED CONDITIONS
		########################################

		# ASLEEP: perception degree 3 removes, sudden movement removes
		{
			:key => :asleep, 
			:degree => 3, 
			:modifiers => [:defenseless, :stunned, :unaware], 
			:recovery => false
		},
		
		# BLIND:
		{
			:key => :blind, 
			:degree => 2, 
			:modifiers => [:hindered, :unaware, :vulnerable, :impaired], 
			:recovery => false
		},
		
		# BOUND:
		{
			:key => :bound, 
			:degree => 2, 
			:modifiers => [:defenseless, :immobile, :impaired], 
			:recovery => false
		},
		
		# DEAF:
		{
			:key => :deaf, 
			:degree => 2, 
			:modifiers => [:unaware], 
			:recovery => false
		},
		
		# DYING:
		{
			:key => :dying, 
			:degree => 4, 
			:modifiers => [:incapacitated], 
			:recovery => false
		},
		
		# ENTRANCED: take no action, any threat ends entranced
		{
			:key => :entranced, 
			:degree => 1, 
			:modifiers => [:action_none], 
			:recovery => true
		},

		# EXHAUSTED:
		{
			:key => :exhausted, 
			:degree => 2, 
			:modifiers => [:impaired, :hindered], 
			:recovery => false,
			:replace => :fatigued
		},
		
		# INCAPICITATED:
		{
			:key => :incapacitated, 
			:degree => 3, 
			:modifiers => [:defenseless, :stunned, :unaware, :prone], 
			:recovery => false
		}, 
		
		# PARALYZED: Physically immobile but can take purely mental actions
		{
			:key => :paralyzed, 
			:degree => 3, 
			:modifiers => [:defenseless, :immobile, :stunned], 
			:recovery => false
		},

		# PRONE:
		#   really gives close attacks +5 and ranged -5 but for purposes of the sim the status effect was worst case
		{
			:key => :prone, 
			:degree => 2, 
			:modifiers => [
				:hindered, 
				[:defense, :value, lambda{|x| x - 5}, "prone: -5 defense"]], 
			:recovery => false
		},
		
		# RESTRAINED:
		{
			:key => :restrained, 
			:degree => 2, 
			:modifiers => [:hindered, :vulnerable], 
			:recovery => false
		},
		
		# STAGGERED:
		{
			:key => :staggered, 
			:degree => 2, 
			:modifiers => [:dazed, :hindered], 
			:recovery => false
		},
		
		# SUPRISED:
		{
			:key => :suprised, 
			:degree => 1, 
			:modifiers => [:stunned, :vulnerable], 
			:recovery => true
		},

		########################################
		# SPECIAL CONDITONS FOR PROGRAM
		########################################
		{
			:key => :action_partial, 
			:degree => 0, 
			:modifiers => [[:character, :actions, lambda{|x| :partial}, "partial actions"]], 
		},
		{
			:key => :action_none, 
			:degree => 0, 
			:modifiers => [[:character, :actions, lambda{|x| :none}, "no actions"]], 
			:replace => :action_partial
		},
		{
			:key => :actions_controlled, 
			:degree => 0, 
			:modifiers => [[:character, :is_controlled, lambda{|x| true}, "actions controlled"]], 
		},

	].each do |v| Status.new(v) end

end