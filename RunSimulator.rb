#!/usr/bin/ruby
require "./SimulatorLib.rb"

def fork_sim(name, attack)
	fork {
		attacker = Character.new(
		{
			:name => "Atacker",
			:attack => attack,
			:defense => nil,
			:initiative => 0
		})

		defender = Character.new(
		{
			:name => "Defender",
			:attack => nil,
			:defense => Defense.new,
			:initiative => 0
		})

		result = CombatSimulator.new({ :character1 => attacker, :character2 => defender }).run.format_stats
		puts "==========\n#{name}\n#{result}=========="
	}
end

fork_sim("BASIC DAMAGE", Attack::create_damage)
fork_sim("BASIC AFFLICTION", Attack::create_affliction)
fork_sim("CUMULATIVE AFFLICTION", Attack::create_affliction({:cumulative_statuses=>[1,2]}))
fork_sim("PROGRESSIVE AFFLICTION", Attack::create_affliction({:is_progressive=>true}))
fork_sim("CUMULATIVE+PROGRESSIVE AFFLICTION", 
	Attack::create_affliction({ :cumulative_statuses=>[1,2], :is_progressive=>true }))
Process.waitall