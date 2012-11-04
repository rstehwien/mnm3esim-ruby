require 'test_helper'
require 'mnm3esim'
include MnM3eSim

class DefaultTest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_degree
  	dc = 20
    generate_expected_degree(dc).each{|v|
    	assert_equal(v[1], MnM3eBase::check_degree(dc, v[0]))
    }
  end

  def generate_expected_degree(dc)
  	# [Check Result Equal or Greater Than DC + X, Degree]
 	# test at each X+1, X, and X-1
   	[
   		[dc+16,4], [dc+15,4], [dc+14,3],
   		[dc+11,3], [dc+10,3], [dc+9,2],
   		[dc+6,2],  [dc+5,2],  [dc+4,1],
   		[dc+1,1],  [dc+0,1],  [dc-1,-1],
   		[dc-4,-1], [dc-5,-1], [dc-6,-2],
   		[dc-9,-2], [dc-10,-2],[dc-11,-3],
   		[dc-14,-3],[dc-15,-3],[dc-16,-4],
   		[dc-19,-4],[dc-20,-4],[dc-21,-5]
   	]
  end
end
