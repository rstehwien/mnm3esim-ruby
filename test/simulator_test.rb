require 'test_helper'
require 'mnm3esim'
include MnM3eSim

class SimulatorTest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_default
      attacker = Character.new({:name => "Atacker", :attack => Attack.new})
      defender = Character.new({:name => "Defender", :defense => Defense.new})
      simulator = CombatSimulator.new({ :iterations =>1000, :character1 => attacker, :character2 => defender })
      result = simulator.run
      assert(result[:min] > 0, "min better be > 1")
      assert((result[:mean]-10.1).abs < 0.75, "mean must be within .75 of 10.1 and was #{result[:mean]}")
  end

end
