module MnM3eSim
	StatusModifier = SuperStruct.new(:group, :property, :modifier, :description)

	class Status < SuperStruct.new(:status, :degree, :modifiers, :recovery, :replace)
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
			raise ArgumentError, "Status not unique #{self.status}" if STATUSES.has_key? self.status
			STATUSES[self.status] = self
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

		def self.expand_statuses(value)
			result = {}
			Array(value).each do |v| 
				status = get_status(v)
				next if status == nil

				result[status.status] = status

				result = result.merge(expand_statuses(status.modifiers)) if status.modifiers.is_a? Array
			end

			# remove any we replace
			result.inject([]) {|a,(k,status)| a.concat(Array(status.replace))}.each do |d| result.delete(d) end

			result[:normal] = STATUSES[:normal] if result.length < 1
			result.delete(:normal) if result.length > 1

			result
		end

		def self.all_modifiers(value)
			statuses = expand_statuses(value)

			modifiers = []
			statuses.each do |k,status|
				Array(status.modifiers).each do |m|
					modifiers.push(StatusModifier.new(*m)) if m.is_a? Array
				end
			end
			modifiers
		end

		def self.degree(value)
			statuses = expand_statuses(value)
			statuses.inject([]) {|a,(k,status)| a.push(status.degree);a}.max
		end
	end

	# ALL STANDARD STATUSES
	[
		# NORMAL 
		{:status => :normal, :degree => 0, :modifiers => nil, :recovery => false, :replace => nil}, 

		########################################
		# BASIC CONDITIONS
		########################################
		# COMPELLED: action chosen by controller, limited to free actions and a single standard action per turn
		{
			:status => :compelled, 
			:degree => 2, 
			:modifiers => [:action_partial, :actions_controlled], 
			:recovery => false
		},

		# CONTROLLED: full actions chosen by controller
		{
			:status => :controlled, 
			:degree => 3, 
			:modifiers => [:actions_controlled], 
			:recovery => false,
			:replace => :compelled
		},
		
		# DAZED: limited to free actions and a single standard action per turn
		{
			:status => :dazed, 
			:degree => 1, 
			:modifiers => [:action_partial], 
			:recovery => false
		}, 
		
		# DEBILITATED: The character has one or more abilities lowered below –5.
		{
			:status => :debilitated, 
			:degree => 3, 
			:modifiers => [:action_none], 
			:recovery => false,
			:replace => [:disabled, :weakened]
		},

		# DEFENSELESS: defense = 0
		{
			:status => :defenseless, 
			:degree => 2, 
			:modifiers =>  [[:defense, :value, lambda{|x|0}, "defenseless"]], 
			:recovery => false,
			:replace => :vulnerable
		},

		# DISABLED: checks - 5 
		{
			:status => :disabled, 
			:degree => 2, 
			:modifiers =>  [[:ALL, :roll_d20, lambda{|x| x - 5}, "disabled; -5 to checks"]], 
			:recovery => false,
			:replace => :impaired
		},

		# FATIGUED: hindered, recover in an hour
		{
			:status => :fatigued, 
			:degree => 1, 
			:modifiers => [:hindered], 
			:recovery => false
		}, 

		# HINDERED: speed - 1 (half speed)
		{
			:status => 
			:hindered, :degree => 1, 
			:modifiers => [[:character, :speed, lambda{|x| x - 1}, "hindered: -1 speed"]], 
			:recovery => false
		},
		
		# IMMOBLE:
		{
			:status => :immobile, 
			:degree => 2, 
			:modifiers =>  [[:character, :speed, lambda{|x| nil}, "immoble: no speed"]], 
			:recovery => false,
			:replace => :hindered
		},
		
		# IMPAIRED: checks - 2 
		{
			:status => :impaired, 
			:degree => 1, 
			:modifiers => [[:ALL, :roll_d20, lambda{|x| x - 2}, "impaired; -2 to checks"]], 
			:recovery => false
		},

		# STUNNED:
		{
			:status => :stunned, 
			:degree => 2, 
			:modifiers => [:action_none], 
			:recovery => false,
			:replace => :dazed
		},

		# TRANSFORMED: becomes something else
		{
			:status => :transformed, 
			:degree => 3, 
			:modifiers => [:action_none], 
			:recovery => false
		},
		
		# UNAWARE:unaware of surroundings and unable to act on it
		{
			:status => :unaware, 
			:degree => 3, 
			:modifiers => [:action_none], 
			:recovery => false
		},
		
		# VULNERABLE: defense.value/2 [RU]
		{
			:status => :vulnerable, 
			:degree => 1, 
			:modifiers => [[:defense, :value, lambda{|x| (x.to_f/2).ceil}, "vulnerable: 1/2 defense"]], 
			:recovery => false
		},
		
		# WEAKENED: trait is lowered
		{
			:status => :weakened, 
			:degree => 1, 
			:modifiers => nil, 
			:recovery => false
		},
		
		########################################
		# COMBINED CONDITIONS
		########################################

		# ASLEEP: perception degree 3 removes, sudden movement removes
		{
			:status => :asleep, 
			:degree => 3, 
			:modifiers => [:defenseless, :stunned, :unaware], 
			:recovery => false
		},
		
		# BLIND:
		{
			:status => :blind, 
			:degree => 2, 
			:modifiers => [:hindered, :unaware, :vulnerable, :impaired], 
			:recovery => false
		},
		
		# BOUND:
		{
			:status => :bound, 
			:degree => 2, 
			:modifiers => [:defenseless, :immobile, :impaired], 
			:recovery => false
		},
		
		# DEAF:
		{
			:status => :deaf, 
			:degree => 2, 
			:modifiers => [:unaware], 
			:recovery => false
		},
		
		# DYING:
		{
			:status => :dying, 
			:degree => 4, 
			:modifiers => [:incapacitated], 
			:recovery => false
		},
		
		# ENTRANCED: take no action, any threat ends entranced
		{
			:status => :entranced, 
			:degree => 1, 
			:modifiers => [:action_none], 
			:recovery => true
		},

		# EXHAUSTED:
		{
			:status => :exhausted, 
			:degree => 2, 
			:modifiers => [:impaired, :hindered], 
			:recovery => false,
			:replace => :fatigued
		},
		
		# INCAPICITATED:
		{
			:status => :incapacitated, 
			:degree => 3, 
			:modifiers => [:defenseless, :stunned, :unaware, :prone], 
			:recovery => false
		}, 
		
		# PARALYZED: Physically immobile but can take purely mental actions
		{
			:status => :paralyzed, 
			:degree => 3, 
			:modifiers => [:defenseless, :immobile, :stunned], 
			:recovery => false
		},

		# PRONE:
		#   really gives close attacks +5 and ranged -5 but for purposes of the sim the status effect was worst case
		{
			:status => :prone, 
			:degree => 2, 
			:modifiers => [
				:hindered, 
				[:defense, :value, lambda{|x| x - 5}, "prone: -5 defense"]], 
			:recovery => false
		},
		
		# RESTRAINED:
		{
			:status => :restrained, 
			:degree => 2, 
			:modifiers => [:hindered, :vulnerable], 
			:recovery => false
		},
		
		# STAGGERED:
		{
			:status => :staggered, 
			:degree => 2, 
			:modifiers => [:dazed, :hindered], 
			:recovery => false
		},
		
		# SUPRISED:
		{
			:status => :suprised, 
			:degree => 1, 
			:modifiers => [:stunned, :vulnerable], 
			:recovery => true
		},

		########################################
		# SPECIAL CONDITONS FOR PROGRAM
		########################################
		{
			:status => :action_partial, 
			:degree => 0, 
			:modifiers => [[:character, :actions, lambda{|x| :partial}, "partial actions"]], 
		},
		{
			:status => :action_none, 
			:degree => 0, 
			:modifiers => [[:character, :actions, lambda{|x| :none}, "no actions"]], 
			:replace => :action_partial
		},
		{
			:status => :actions_controlled, 
			:degree => 0, 
			:modifiers => [[:character, :is_controlled, lambda{|x| true}, "actions controlled"]], 
		},

	].each do |v| Status.new(v) end

end