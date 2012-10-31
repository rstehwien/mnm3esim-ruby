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
		:is_multiattack => false
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
		:is_multiattack => false
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

	def roll_attack(defense_class)
		damage_impervious = @rank
		damage = @rank

		return {:degree=>1, :damage=>damage, :damage_impervious=>damage_impervious} if @is_perception_attack

		hit_roll = MnM.roll_d20

		# roll of 1 automatically misses
		return {:degree=>-1, :damage=>0, :damage_impervious=>0} if hit_roll == 1

		hit_degree = MnM.degree(defense_class+10, hit_roll + @bonus)

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
	attr_accessor :defense_class
	attr_accessor :save
	attr_accessor :impervious # any attack difficulty less is ignored

	def self.defaults
		{
		:defense_class => 10,
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
	attr_accessor :initiative_bonus
	attr_reader :initiative
	attr_reader :status
	attr_reader :stress # stress is equivalent to the "cumulative -1 to resistance"

	def self.defaults
		{
    	:name => "Character",
		:attack => nil,
		:defense => nil,
		:initiative_bonus => 0
	    }
	end

	def initialize(args={})
	    Character::defaults.merge(args).each {|k,v| send("#{k}=",v)}
	    init_combat
	end

	def init_combat
		@stress = 0
		@status = 0
		@initiative = MnM.roll_d20(@initiative_bonus)
	end

	def attack_target(target)
		attack = @attack 			# my attack
		defense = target.defense 	# targets defense
		# bail if attack or defense is nil
		return if attack == nil or defense == nil

		#puts("#{@name} attacks #{target.name}")

		result = attack.roll_attack(defense.defense_class)
		#puts("Hit Roll Degrees: #{result[:degree]} Damage: #{result[:damage]}")

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

		status = degree > 0 ? nil : degree.abs
		#puts("Resistance Roll: #{save_roll} Total: #{resistance} Degree: #{degree} Status: #{status}")

		# if stress is caused, it is for a status effect of -1 and higher (equivalent to save of rank+15)
		@stress += 1 if attack.is_cause_stress and degree <= 1

		update_status(attack, status) if status != nil

		#puts("#{@name} Stress: #{@stress} Status: #{@status}")
	end

	def update_status(attack, status)
		return if status < 1 # no status inflicted
		
		# if status greater than current, becomes new status
		if status > @status then
			@status = status
		else
			#puts("BUMP CUMULATIVE")
			# increate status if cumulative
			@status += 1 if attack.cumulative_statuses.include?(status)
		end
	end

	def end_round_recovery(attack)
		# bail if no recovery check needed; 
		return if attack == nil or !attack.is_status_recovery or @defense == nil or @status > 2 or @status < 1

		resistance = MnM.degree(attack.rank + 10, @defense.save + MnM.roll_d20)
		# if resistance sucessful, lower the status by one
		if resistance > 0
			#puts("SUCCESSFUL RESISTANCE")
			@status -= 1
		# if failed and progressive, increase status by one
		elsif attack.is_progressive
			#puts("FAILED PROGRESSIVE")
			@status += 1
		end
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
	    @init_order.sort! { |a, b|  a.initiative <=> b.initiative }
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
		@character1.status > 2 or @character2.status > 2
	end

	def run_round
		@init_order[0].attack_target(@init_order[1])
		@init_order[0].end_round_recovery(@init_order[1].attack)
		return if combat_finished?

		@init_order[1].attack_target(@init_order[0])
		@init_order[1].end_round_recovery(@init_order[0].attack)
	end
end

