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
  
end
