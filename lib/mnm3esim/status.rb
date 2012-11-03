module MnM3eSim
	class Status
		attr_accessor :status
		attr_accessor :degree
		# array of modifiers in form of one of the following
		# nil => no modifiers this program can express currently
		# [symbolN,modifierN] => an array of any number of symbols or modifiers
		# symbol is another status
		# mofifier is an array of
		# 	[target, property, lambda]
		# where target is one of :all, :character, :attack, :defense
		attr_accessor :modifiers
		attr_accessor :recovery # if automatically recovered, actual recovery varies but this is simplified for sim

		def initialize(args={})
		    {:degree => 0, :modifiers => nil, :recovery => false}.merge(args).each {|k,v| send("#{k}=",v)}
		end

		def modifiers=(value)
			@modifiers = parse_modifiers(value)
		end

		def parse_modifiers(value)
			if value.kind_of? Array then
				m = value.inject([]) {|a,v|
					if v.kind_of? Array then
						a.push(v)
					elsif v.is_a? Symbol then
						m = parse_modifiers(Status::STATUS_MAP[v][:modifiers])
						a.concat(m) if m != nil
					end
					a
				}
				m.length < 1 ? nil : m
			else
				nil
			end				
		end

		STATUS_MAP=
		[
			{:status => :none, :degree => 0, :modifiers => nil, :recovery => false}, 
			{:status => :generic1, :degree => 1, :modifiers => nil, :recovery => false}, 
			{:status => :generic2, :degree => 2, :modifiers => nil, :recovery => false}, 
			{:status => :generic3, :degree => 3, :modifiers => nil, :recovery => false}, 

			# DAZED: limited to free actions and a single standard action per turn
			{
				:status => :dazed, 
				:degree => 1, 
				:modifiers => 
				[
					[:character, :actions, lambda{|x| :partial}],
					[:character, :is_controlled, lambda{|x|true}]
				], 
				:recovery => false
			}, 
			
			# ENTRANCED: take no action, any threat ends entranced
			{:status => :entranced, :degree => 1, :modifiers => [[:character, :actions, lambda{|x| :none}]], :recovery => true},
			# FATIGUED: hindered
			{:status => :fatigued, :degree => 1, :modifiers => [:hindered], :recovery => false}, 
			# HINDERED: speed - 1 (half speed)
			{:status => :hindered, :degree => 1, :modifiers => [[:character, :speed, lambda{|x| x - 1}]], :recovery => false},
			# IMPAIRED: checks - 2 
			{:status => :impaired, :degree => 1, :modifiers => [[:defense, :roll_d20, lambda{|x| x - 2}]], :recovery => false}, 
			# VULNERABLE: defense.value/2 [RU]
			{:status => :vulnerable, :degree => 1, :modifiers => [[:defense, :value, lambda{|x| (x.to_f/2).ceil}]], :recovery => false},
			# COMPELLED: action chosen by controller, limited to free actions and a single standard action per turn
			{:status => :compelled, :degree => 2, :modifiers =>  [[:character, :actions, lambda{|x| :partial}]], :recovery => false},
			# DEFENSELESS: defense = 0
			{:status => :defenseless, :degree => 2, :modifiers =>  [[:defense, :value, lambda{|x|0}]], :recovery => false},
			# DISABLED: checks - 5 
			{:status => :disabled, :degree => 2, :modifiers =>  [[:defense, :roll_d20, lambda{|x| x - 5}]], :recovery => false},
			# EXHAUSTED:
			{:status => :exhausted, :degree => 2, :modifiers => [[:all, :roll_d20, lambda{|x| x - 2}], :hindered], :recovery => false},
			# IMMOBLE:
			{:status => :immobile, :degree => 2, :modifiers =>  [[:character, :speed, lambda{|x| nil}]], :recovery => false},
			# PRONE:
			#   really gives close attacks +5 and ranged -5 but for purposes of the sim the status effect was worst case
			{:status => :prone, :degree => 2, :modifiers => [:hindered, [:defense, :value, lambda{|x| x - 5}]], :recovery => false},
			# STUNNED:
			{:status => :stunned, :degree => 2, :modifiers => [[:character, :actions, lambda{|x| :none}]], :recovery => false},
			# STAGGERED:
			{:status => :staggered, :degree => 2, :modifiers => [:dazed, :hindered], :recovery => false},
			# ASLEEP: perception degree 3 removes, sudden movement removes
			{:status => :asleep, :degree => 3, :modifiers => [:defenseless, :stunned, :unaware], :recovery => false},
			# CONTROLLED: full actions chosen by controller
			{:status => :controlled, :degree => 3, :modifiers => [[:character, :is_controlled, lambda{|x|true}]], :recovery => false},
			# INCAPICITATED:
			{:status => :incapacitated, :degree => 3, :modifiers => [:defenseless, :stunned, :unaware, :prone], :recovery => false}, 
			# PARALYZED: Physically immobile but can take purely mental actions
			{:status => :paralyzed, :degree => 3, :modifiers => [:defenseless, :immobile, :stunned], :recovery => false},
			# TRANSFORMED: becomes something else
			{:status => :transformed, :degree => 3, :modifiers => [[:character, :actions, lambda{|x| :none}]], :recovery => false},
			# UNAWARE:unaware of surroundings and unable to act on it
			{:status => :unaware, :degree => 3, :modifiers => [[:character, :actions, lambda{|x| :none}]], :recovery => false},
		].inject({}) {|h, e| h[e[:status]]=e; h }
		STATUSES=STATUS_MAP.inject({}) {|h, (k, v)| h[k]=Status.new(v); h }
	end
end