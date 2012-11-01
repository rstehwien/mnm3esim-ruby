#!/usr/bin/ruby
require 'yaml'

class MnM
	def self.roll_d20(bonus=0)
		rand(20)+1+bonus
	end

	def self.degree(difficulty, check)
		result = check - difficulty
		(result/5) + (result<0 ? 0 : 1)
	end
end

class Status
	attr_accessor :status
	attr_accessor :degree
	# array of modifiers in form of one of the following
	# nil => no modifiers this program can express currently
	# [symbolN,modifierN] => an array of any number of symbols or modifiers
	# symbol is another status
	# mofifier is an array to modify some value
	# 	[property, lambda]
	# 	[:attack, property, lambda]
	# 	[:defense, property, lambda]
	attr_accessor :modifiers
	attr_accessor :recovery # if automatically recovered, actual recovery varies but this is simplified for sim

	def initialize(args={})
	    {:degree => 0, :modifiers => nil, :recovery => false}.merge(args).each {|k,v| send("#{k}=",v)}
	end

	STATUSES=
	[
		{:status => :none, :degree => 0, :modifiers => nil, :recovery => false}, 
		{:status => :generic1, :degree => 1, :modifiers => nil, :recovery => false}, 
		{:status => :generic2, :degree => 2, :modifiers => nil, :recovery => false}, 
		{:status => :generic3, :degree => 3, :modifiers => nil, :recovery => false}, 

		# DAZED: limited to free actions and a single standard action per turn
		{:status => :dazed, :degree => 1, :modifiers => :nil, :recovery => false}, 
		# ENTRANCED: take no action, any threat ends entranced
		{:status => :entranced, :degree => 1, :modifiers => nil, :recovery => true}, # [:is_act, lambda{|x|false}]
		# FATIGUED: hindered
		{:status => :fatigued, :degree => 1, :modifiers => [:hindered], :recovery => false}, 
		# HINDERED: speed - 1 (half speed)
		{:status => :hindered, :degree => 1, :modifiers => nil, :recovery => false}, #[[:speed, lambda{|x| x - 1}]] 
		# IMPAIRED: X - 2 #could impare any value choosing save for sim
		{:status => :impaired, :degree => 1, :modifiers => [[:defense, :save, lambda{|x| x - 2}]], :recovery => false}, 
		# VULNERABLE: defense.value/2 [RU]
		{:status => :vulnerable, :degree => 1, :modifiers => [[:defense, :value, lambda{|x| (x.to_f/2).ceil}]], :recovery => false},
		# COMPELLED: action chosen by controller, limited to free actions and a single standard action per turn
		{:status => :compelled, :degree => 2, :modifiers => nil, :recovery => false}, # [:is_act, lambda{|x|false}]
		# DEFENSELESS: defense = 0
		{:status => :defenseless, :degree => 2, :modifiers =>  [[:defense, :value, lambda{|x|0}]], :recovery => false},
		# DISABLED: X - 5 # could disable any value, choosing save for sim
		{:status => :disabled, :degree => 2, :modifiers =>  [[:defense, :save, lambda{|x| x - 5}]], :recovery => false},
		# EXHAUSTED:
		{:status => :exhausted, :degree => 2, :modifiers => [[:all, lambda{|x| x - 2}], :hindered], :recovery => false},
		# IMMOBLE:
		{:status => :immobile, :degree => 2, :modifiers =>  nil, :recovery => false}, #[[:speed, lambda{|x| nil}]]
		# PRONE:
		{:status => :prone, :degree => 2, :modifiers => [:hindered, [:defense, :value, lambda{|x| x - 5}]], :recovery => false}, # really gives close attacks +5 and ranged -5 but for purposes of the sim the status effect was worst case
		# STUNNED:
		{:status => :stunned, :degree => 2, :modifiers => nil, :recovery => false}, #[:is_act, lambda{|x|false}]
		# STAGGERED:
		{:status => :staggered, :degree => 2, :modifiers => [:dazed, :hindered], :recovery => false},
		# ASLEEP:
		{:status => :asleep, :degree => 3, :modifiers => [:defenseless, :stunned, :unaware], :recovery => false}, #perception degree 3 removes, sudden movement removes
		# CONTROLLED: full actions chosen by controller
		{:status => :controlled, :degree => 3, :modifiers => nil, :recovery => false},
		# INCAPICITATED:
		{:status => :incapacitated, :degree => 3, :modifiers => [:defenseless, :stunned, :unaware, :prone], :recovery => false}, 
		# PARALYZED: Physically immobile but can take purely mental actions
		{:status => :paralyzed, :degree => 3, :modifiers => [:defenseless, :immobile, :stunned], :recovery => false}, # can take mental actions
		# TRANSFORMED: 
		{:status => :transformed, :degree => 3, :modifiers => nil, :recovery => false}, # becomes something else
		# UNAWARE:
		{:status => :unaware, :degree => 3, :modifiers => nil, :recovery => false}, # unaware of surroundings and unable to act on it
	].inject({}) {|h, e| h[e[:status]]=e; h }


end

class Attack
	attr_accessor :bonus
	attr_accessor :rank
	attr_accessor :penetrating
	attr_accessor :is_cause_stress
	attr_accessor :is_perception_attack
	attr_accessor :min_crit
	attr_accessor :cumulative_statuses # array of statuses that cause bump to next.  either [], [2], or [1,2]
	attr_accessor :is_status_recovery
	attr_accessor :is_progressive
	attr_accessor :is_multiattack
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

	def self.create_damage(args={})
		Attack.new(Attack::defaults_damage.merge(args))
	end
	def self.create_affliction(args={})
		Attack.new(Attack::defaults_affliction.merge(args))
	end

	def initialize(args={})
	    Attack::defaults_damage.merge(args).each {|k,v| send("#{k}=",v)}
	end

	def roll_attack(value)
		damage_impervious = @rank
		damage = @rank

		return {:degree => 1, :damage=>damage, :damage_impervious=>damage_impervious} if @is_perception_attack

		hit_roll = MnM.roll_d20

		# roll of 1 automatically misses
		return {:degree=>-1, :damage=>0, :damage_impervious=>0} if hit_roll == 1

		hit_degree = MnM.degree(value+10, hit_roll + @bonus)

		# crit if you hit and got the min_crit or better
		is_crit = (hit_degree > 0 and hit_roll >= @min_crit)

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
		if @is_multiattack and hit_degree > 1 then
			damage += hit_degree >= 3 ? 5 : 2
		end

		{:degree=>hit_degree, :damage=>damage, :damage_impervious=>damage_impervious}
	end
end

class Defense
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

class Character
	attr_accessor :name
	attr_accessor :attack
	attr_accessor :defense
	attr_accessor :initiative
	attr_reader :initiative_value
	attr_reader :status
	attr_reader :stress # stress is equivalent to the "cumulative -1 to resistance"

	def self.defaults
		{
    	:name => "Character",
		:attack => nil,
		:defense => nil,
		:initiative => 0
	    }
	end

	def initialize(args={})
	    Character::defaults.merge(args).each {|k,v| send("#{k}=",v)}
	    init_combat
	end

	def init_combat
		@stress = 0
		set_status(:none)
		@initiative_value = MnM.roll_d20(@initiative)
	end

	def attack_target(target)
		attack = @attack 			# my attack
		defense = target.defense 	# targets defense
		# bail if attack or defense is nil
		return if attack == nil or defense == nil

		result = attack.roll_attack(defense.value)

		# apply the damage if needed
		if result[:degree] > 0 then
			target.apply_damage(attack, result[:damage])
		end
	end

	def apply_damage(attack, damage)
		# bail if impervious to this attack
		if @defense.impervious != nil then
			impervious = @defense.impervious - attack.penetrating
			return if impervious >= damage[:damage_impervious]
		end

		# Always roll vs Damage+10 to determin status and stress
		# The degree will be the status inflicted
		# Stress caused if degree <= 1 (equivalent to Damage+15)
		save_roll = MnM.roll_d20
		resistance = save_roll + @defense.save - @stress
		degree = MnM.degree(damage + 10, resistance)

		if save_roll == 20 then
			degree = degree < 1 ? 1 : degree + 1
		end


		# if stress is caused, it is for a status effect of -1 and higher (equivalent to save of rank+15)
		@stress += 1 if attack.is_cause_stress and degree <= 1

		status_degree = degree > 0 ? nil : degree.abs
		update_status(status_degree, attack)
	end

	def update_status(status_degree, attack)
		return if status_degree == nil or status_degree < 1
		
		# if status greater than current, becomes new status
		if status_degree > @status[:degree]
			set_status(status_degree, attack)
		# if cumulative, then status degree bumped up one
		elsif attack.cumulative_statuses.include?(status_degree) then
			set_status(@status[:degree]+1, attack)
		end
	end

	def set_status(sv, attack=nil)
		return if sv == nil

		if sv.is_a? Symbol then
			@status = Status::STATUSES[sv]
		elsif sv.is_a? Fixnum and sv < 1 then
			@status = Status::STATUSES[:none]
		elsif attack != nil and sv.is_a? Fixnum then
			s = attack.statuses[([sv, attack.statuses.length].min)-1]
			@status = Status::STATUSES[s]
		else
			puts sv.class.name
			puts sv.to_yaml
			puts attack.to_yaml

			throw "BAD STATUS"
		end
		if @status == nil or @status[:degree] == nil then
			puts sv.class.name
			puts "sv = #{sv}"
			puts attack.to_yaml
			throw "BAD STATUS"
		end
	end

	def end_round_recovery(attack)
		# bail if no recovery check needed: no attack, no recovery
		return if attack == nil or !attack.is_status_recovery or @defense == nil
		
		status_degree = @status[:degree]
		# bail if nothing to recover or if you can't recover (status too high)
		return if status_degree < 1 or status_degree > 2
		

		resistance = MnM.degree(attack.rank + 10, @defense.save + MnM.roll_d20)
		# if resistance sucessful, lower the status by one
		if resistance > 0
			status_degree -= 1
		# if failed and progressive, increase status by one
		elsif attack.is_progressive
			status_degree += 1
		end

		set_status(status_degree, attack)
	end
end

class CombatSimulator
	# Combat Parameters
	attr_accessor :iterations
	attr_accessor :character1
	attr_accessor :character2

	attr_reader :num_rounds
	attr_reader :init_order

	def self.defaults
		{
		:iterations => 10000,#100000,
		:character1 => Character.new({:attack => Attack.new, :defense => nil}),
		:character2 => Character.new({:attack => nil, :defense => Defense.new})
		}
	end

	def initialize(args={})
	    CombatSimulator::defaults.merge(args).each {|k,v| send("#{k}=",v)}
	end

	def run
		init_run

		for i in 1..@iterations
			run_combat
		end

		len = @num_rounds.length

		rounds_analysis = {}
		rounds_analysis[:rounds_min] = @num_rounds.min
		rounds_analysis[:rounds_max] = @num_rounds.max
		total = @num_rounds.inject{|sum,x| sum + x }
		mean = total.to_f / len
		rounds_analysis[:rounds_mean] = mean
		
		sorted = @num_rounds.sort
		rounds_analysis[:rounds_median] = len % 2 == 1 ? sorted[len/2] : (sorted[len/2 - 1] + sorted[len/2]).to_f / 2
	
		sv = @num_rounds.inject(0){|accum, i| accum + (i - mean) ** 2 }
		variance = sv / (len - 1).to_f
		rounds_analysis[:rounds_variance] = variance
		rounds_analysis[:rounds_standard_deviation] =  Math.sqrt(variance)

		rounds_analysis
	end

	def init_run
	    @num_rounds = []
	end

	def init_combat
	    @character1.init_combat
	    @character2.init_combat
	    @init_order = [character1,character2]
	    @init_order.sort! { |a, b|  a.initiative_value <=> b.initiative_value }
	end

	def run_combat
	    init_combat

	    rounds = 0
	    while !combat_finished? or rounds > 10000
	    	rounds += 1
	    	run_round
	    end
	    @num_rounds.push(rounds)
	end

	def combat_finished?
		@character1.status[:degree] > 2 or @character2.status[:degree] > 2
	end

	def run_round
		@init_order[0].attack_target(@init_order[1])
		@init_order[0].end_round_recovery(@init_order[1].attack)
		return if combat_finished?

		@init_order[1].attack_target(@init_order[0])
		@init_order[1].end_round_recovery(@init_order[0].attack)
	end
end

