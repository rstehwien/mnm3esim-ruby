require 'test_helper'
require 'mnm3esim'
include MnM3eSim

class ModifiableTest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_default
  	a = Attack.new
    Attack.defaults.each {|k,v|
      if v.is_a? Symbol or v.kind_of? Fixnum or v.kind_of? String then
        assert_equal(v, a.send(k), "testing #{k}") 
      end
    }
    assert_equal(10,a.bonus)
  end

  def test_modifier_one
    a = Attack.new({:bonus=>13, :rank => 10})
    assert_equal(13,a.bonus)
    assert_equal(10,a.rank)

    a.add_modifier(:bonus, lambda {|x| x-10})
    assert_equal(3,a.bonus)
    assert_equal(10,a.rank)

    a.bonus = 20
    assert_equal(10,a.bonus)

    a.delete_modifier(:bonus)
    assert_equal(20,a.bonus)
  end

  def test_modifier_all
    a = Attack.new({:bonus=>13, :rank => 10})
    assert_equal(13,a.bonus)
    assert_equal(10,a.rank)

    a.add_modifier(:ALL, lambda {|x| x-10})
    assert_equal(3,a.bonus)
    assert_equal(0,a.rank)

    a.bonus = 20
    assert_equal(10,a.bonus)
    assert_equal(0,a.rank)

    a.delete_modifier(:ALL)
    assert_equal(20,a.bonus)
    assert_equal(10,a.rank)
  end

end
