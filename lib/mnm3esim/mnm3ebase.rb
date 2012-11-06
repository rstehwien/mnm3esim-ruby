module MnM3eSim
	class MnM3eBase
		def self.roll_d20(bonus=0)
			rand(20)+1+bonus
		end

		def self.check_degree(difficulty, check)
			result = check - difficulty
			(result/5) + (result<0 ? 0 : 1)
		end

		#rand(36**8).to_s(36) for tiny token
		@@unique_hashes = []
		def self.get_unique_hash()
			h = nil
			begin
				h = rand(36**8)
			end while @@unique_hashes.include? h
			h
		end

	end
end