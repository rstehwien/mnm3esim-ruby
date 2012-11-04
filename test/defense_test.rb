require 'test_helper'
require 'mnm3esim'
include MnM3eSim

class DefenseTest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_default
    d = Defense.new
    Defense.defaults.each {|k,v|
      if v.is_a? Symbol or v.kind_of? Fixnum or v.kind_of? String then
        assert_equal(v, d.send(k), "testing #{k}") 
      end
    }
    assert_equal(10,d.value)
    assert_equal(10,d.save)
    assert_equal(nil,d.impervious)
  end

  def test_create
  	d = Defense.new({:value=>13,:save=>14,:impervious=>15})
    assert_equal(13,d.value)
    assert_equal(14,d.save)
    assert_equal(15,d.impervious)
  end

  def test_roll
    d = Defense.new({:value=>13,:save=>14,:impervious=>15})
    (-50..50).each {|x|  
      r = d.roll_d20(x)
      assert((r >= (1+x) and r <= (20+x)), "#{r} should be between #{1+x} and #{20+x} inclusive")
    }
  end

  def test_modifier
    d = Defense.new({:value=>13,:save=>14,:impervious=>15})
    d.add_modifier(:value, lambda {|x| x-10})

    assert_equal(3,d.value)
    assert_equal(14,d.save)
    assert_equal(15,d.impervious)

    d.value = 20
    assert_equal(10,d.value)

    d.delete_modifier(:value)
    assert_equal(20,d.value)
  end

  def test_check_degree
    d = Defense.new({:value=>13,:save=>14,:impervious=>15})
    assert_equal(-2,d.check_degree(20, 10))
  end
end
