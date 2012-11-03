module MnM3eSim
	class MnM3eBase
		def self.roll_d20(bonus=0)
			rand(20)+1+bonus
		end

		def self.check_degree(difficulty, check)
			result = check - difficulty
			(result/5) + (result<0 ? 0 : 1)
		end

		def roll_d20(bonus=0)
			MnM3eBase.roll_d20(bonus)
		end

		def check_degree(difficulty, check)
			MnM3eBase.check_degree(difficulty, check)
		end
	end
end