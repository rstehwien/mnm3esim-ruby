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
    assert_equal([:normal], s.to_a)
  end

  def test_expand_none
    s = Status.expand_statuses([:normal])
    assert_equal([:normal], s.to_a)
  end

  def test_expand_impaired
    s = Status.expand_statuses([:impaired])
    assert_equal([:impaired], s.to_a)
  end

  def test_expand_impaired_disabled
    s = Status.expand_statuses([:impaired, :disabled])
    assert_equal([:disabled], s.to_a)
  end

  def test_expand_bad
    assert_raise(ArgumentError, "throw exception on bad status"){Status.expand_statuses([:blarg])}
  end

  def test_expand_incap
    s = Status.expand_statuses([:incapacitated])
    assert_equal([:incapacitated, :defenseless, :stunned, :action_none, :unaware, :prone, :hindered], s.to_a)
  end

  def test_all_modifiers_incap
    m = Status.all_modifiers([:incapacitated])
    assert_equal(4,m.length)
    m.each do |v| 
      assert((v.is_a? Array), "each item better be an array")
    end
  end

end
