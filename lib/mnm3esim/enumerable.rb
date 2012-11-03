module Enumerable
	def statistics
		result = {}

		result[:min] = self.min
		result[:max] = self.max
		
		total = self.inject{|sum,x| sum + x }
		mean = total.to_f / self.length
		result[:mean] = mean
		
		sorted = self.sort
		result[:median] = self.length % 2 == 1 ? sorted[self.length/2] : (sorted[self.length/2 - 1] + sorted[self.length/2]).to_f / 2
	
		sv = self.inject(0){|accum, i| accum + (i - mean) ** 2 }
		variance = sv / (self.length - 1).to_f
		result[:variance] = variance
		result[:standard_deviation] =  Math.sqrt(variance)

		result
	end

	STATS_ORDER = [:min, :max, :mean, :median, :variance, :standard_deviation]

	def format_stats
		STATS_ORDER.inject("") {|s, e| s += "#{(e.to_s+":").ljust(20)} #{self[e]}\n" }
	end
end
