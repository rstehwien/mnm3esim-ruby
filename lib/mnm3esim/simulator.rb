module MnM3eSim
	class CombatSimulator
		# Combat Parameters
		attr_accessor :iterations
		attr_accessor :character1
		attr_accessor :character2

		attr_reader :init_order
		attr_reader :num_rounds

		def self.defaults
			{
			:iterations => 10000,#300000,
			:character1 => Character.new({:attack => Attack.new, :defense => nil}),
			:character2 => Character.new({:attack => nil, :defense => Defense.new})
			}
		end

		def initialize(args={})
		    CombatSimulator::defaults.merge(args).each {|k,v| send("#{k}=",v)}
		    @init_order = nil
		    @num_rounds = nil
		end

		def run
			init_run

			for i in 1..@iterations
				run_combat
			end

			@num_rounds.statistics
		end

		def init_run
		    @num_rounds = []
		end

		def init_combat
		    character1.init_combat
		    character2.init_combat
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
			character1.status_degree > 2 or character2.status_degree > 2
		end

		def run_round
			@init_order[0].attack_target(@init_order[1])
			@init_order[0].end_round_recovery
			return if combat_finished?

			@init_order[1].attack_target(@init_order[0])
			@init_order[1].end_round_recovery
		end
	end

end