require 'test_helper'
require 'mnm3esim'
include MnM3eSim

class CharacterTest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_default
  	c = Character.new
    Character.defaults.each {|k,v|
      if v.is_a? Symbol or v.kind_of? Fixnum or v.kind_of? String then
        assert_equal(v, c.send(k), "testing #{k}") 
      end
    }
    assert_equal(0,c.initiative)
    assert_equal(:full,c.actions)
  end

  def test_modifier
    c = Character.new({:initiative=>13})
    c.add_modifier(:initiative, lambda {|x| x-10})
    assert_equal(3,c.initiative)

    c.initiative = 20
    assert_equal(10,c.initiative)

    c.delete_modifier(:initiative)
    assert_equal(20,c.initiative)
  end

  def test_stress
  	c = Character.new
    c.stress = 7
    assert_equal(7,c.stress)

    c.stress += 1
    assert_equal(8,c.stress)
  end

  def test_status_defense
    a = Attack::create_affliction({:statuses=>[:vulnerable,:defenseless,:incapacitated]})
    c = Character.new({:defense => Defense.new})
    assert_equal(10,c.defense.value)

    c.add_effect(CharacterEffect.new(a, c.defense, 1))
    assert_equal(5,c.defense.value)

    c.add_effect(CharacterEffect.new(a, c.defense, 2))
    assert_equal(0,c.defense.value)

    c.add_effect(CharacterEffect.new(a, c.defense, 3))
    assert_equal(0,c.defense.value)
    assert_equal(3,c.status_degree)
  end

  def test_status_roll
    a = Attack::create_affliction({:statuses=>[:impaired,:disabled,:incapacitated]})
    c = Character.new({:defense => Defense.new})
 
    c.add_effect(CharacterEffect.new(a, c.defense, 1))
    roll_assert(c, 18)
 
    c.add_effect(CharacterEffect.new(a, c.defense, 2))
    roll_assert(c, 15)
  end

  def roll_assert(c, max)
    (1..1000).each do |i| 
      r = c.roll_d20
      assert(r <= max, "character can't roll over #{max} rolled #{r}")
      if c.defense != nil then
        r = c.defense.roll_d20
        assert(r <= max, "defense can't roll over #{max} rolled #{r}")
      end
      if c.attack != nil then
        r = c.attack.roll_d20
        assert(r <= max, "attack can't roll over #{max} rolled #{r}")
      end
    end
  end
  
end
