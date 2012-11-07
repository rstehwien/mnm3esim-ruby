module MnM3eSim

	class ModifiableStructData

		def self.attr_accessor_modifiable(*syms)
			syms.each do |sym|
				property = sym.to_s
				class_eval %Q"
					def #{property}=(value)
						@#{property} = value
					end
					def #{property}
						apply_modifiers(\"#{property}\", @#{property})
					end
				"
			end
		end

		def initialize(args={})
			clear_modifiers
			args.each {|k,v| send("#{k}=",v)}

			@myhash = MnM3eBase::get_unique_hash
		end

		def hash
			@myhash
		end

		def clear_modifiers
			@modifiers = {}
		end

		def add_modifier(property, modifier)
			property = property.to_sym
			@modifiers[property] ||= []
			@modifiers[property].push(*Array(modifier))
		end

		def delete_modifier(property)
			@modifiers.delete(property)
		end

		def roll_d20(bonus=0)
			apply_modifiers(:roll_d20, MnM3eBase.roll_d20(bonus))
		end

		def check_degree(difficulty, check)
			apply_modifiers(:check_degree, MnM3eBase.check_degree(difficulty, check))		
		end

		protected
		def apply_modifiers(property, value)
			property = property.to_sym
		
			return value if !(@modifiers.has_key? property) and !(@modifiers.has_key? :ALL)

			Array(@modifiers[property]).concat(Array(@modifiers[:ALL])).each{|modifier| 
				value = modifier.call(value)
			}

			value
		end
	end
end