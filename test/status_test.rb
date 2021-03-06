require 'test_helper'
require 'mnm3esim'
include MnM3eSim

class Statustest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_expand_nil
    s = Status.expand_statuses(nil)
    assert_equal([:normal], s.keys)
  end

  def test_expand_none
    s = Status.expand_statuses(:normal)
    assert_equal([:normal], s.keys)
  end

  def test_expand_impaired
    s = Status.expand_statuses([:impaired])
    assert_equal([:impaired], s.keys)
  end

  def test_expand_impaired_disabled
    s = Status.expand_statuses([:impaired, :disabled])
    assert_equal([:disabled], s.keys)
  end

  def test_expand_bad
    assert_raise(ArgumentError, "throw exception on bad status"){Status.expand_statuses([:blarg])}
  end

  def test_expand_incap
    s = Status.expand_statuses([:incapacitated])
    assert_equal([:incapacitated, :defenseless, :stunned, :action_none, :unaware, :prone, :hindered].sort_by {|sym| sym.to_s}, s.keys.sort_by {|sym| sym.to_s})
  end

  def test_expand_incap_status
    s = Status.expand_statuses(Status.get_status :incapacitated)
    assert_equal([:incapacitated, :defenseless, :stunned, :action_none, :unaware, :prone, :hindered].sort_by {|sym| sym.to_s}, s.keys.sort_by {|sym| sym.to_s})
  end

  def test_all_modifiers_incap
    m = Status.all_modifiers([:incapacitated])

    assert_equal(4,m.length)
    m.each do |v| 
      assert((v.is_a? StatusModifier), "each item better be a StatusModifier #{v.to_yaml}")
      assert((v.group.is_a? Symbol), "group better be a symbol #{v.to_yaml}")
      assert((v.property.is_a? Symbol), "property better be a symbol #{v.to_yaml}")
      assert((v.modifier.is_a? Proc), "modifier better be a Proc #{v.to_yaml}")
      assert((v.description == nil or (v.description.is_a? String)), "description better be nil or string #{v.to_yaml}")
    end
  end

  def test_degree_normal
    assert_equal(0,Status.degree(:normal))
  end

  def test_degree_several_one
    assert_equal(1,Status.degree([:dazed]))
    assert_equal(1,Status.degree(:hindered))
    assert_equal(1,Status.degree([:dazed,:fatigued,:hindered]))
  end

  def test_degree_several_two
    assert_equal(2,Status.degree(:stunned))
    assert_equal(2,Status.degree([:dazed,:immobile,:stunned]))
  end

  def test_degree_several_three
    assert_equal(3,Status.degree(:transformed))
    assert_equal(3,Status.degree([:transformed,:fatigued,:stunned]))
  end

  def test_degree_incap
    assert_equal(3,Status.degree(Status.expand_statuses(:incapacitated)))
  end
end
