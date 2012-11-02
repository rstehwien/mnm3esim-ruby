#!/usr/bin/ruby
require "./SimulatorLib.rb"

attacker = Character.new(
{
	:name => "Atacker",
	:attack => nil,
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

puts "=========="
puts "BASIC DAMAGE"
attacker.attack = Attack::create_damage
puts CombatSimulator.new({ 
	:character1 => attacker, 
	:character2 => defender
	}).run.format_stats
puts "=========="


puts "=========="
puts "BASIC AFFLICTION"
attacker.attack = Attack::create_affliction
puts CombatSimulator.new({ 
	:character1 => attacker, 
	:character2 => defender
	}).run.format_stats
puts "=========="

puts "=========="
puts "CUMULATIVE AFFLICTION"
attacker.attack = Attack::create_affliction({:cumulative_statuses=>[1,2]})
puts CombatSimulator.new({ 
	:character1 => attacker, 
	:character2 => defender
	}).run.format_stats
puts "=========="

puts "=========="
puts "PROGRESSIVE AFFLICTION"
attacker.attack = Attack::create_affliction({:is_progressive=>true})
puts CombatSimulator.new({ 
	:character1 => attacker, 
	:character2 => defender
	}).run.format_stats
puts "=========="

puts "=========="
puts "CUMULATIVE+PROGRESSIVE AFFLICTION"
attacker.attack = Attack::create_affliction(
	{
		:cumulative_statuses=>[1,2],
		:is_progressive=>true
	})
puts CombatSimulator.new({ 
	:character1 => attacker, 
	:character2 => defender
	}).run.format_stats
puts "=========="

