module MnM3eSim


	class ModifiableStructData

		def self.attr_accessor_modifiable(*syms)
			syms.each do |sym|
				attr_name = sym.to_s
				class_eval %Q"
					def #{attr_name}=(value)
						@#{attr_name} = value
					end
					def #{attr_name}
						apply_modifiers(\"#{attr_name}\", @#{attr_name})
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

		def add_modifier(prop, mod)
			@modifiers[prop] = [] if !@modifiers.has_key?(prop)
			@modifiers[prop].push(mod)
		end

		def delete_modifier(prop)
			@modifiers.delete(prop)
		end

		def roll_d20(bonus=0)
			apply_modifiers(:roll_d20, MnM3eBase.roll_d20(bonus))
		end

		def check_degree(difficulty, check)
			apply_modifiers(:check_degree, MnM3eBase.check_degree(difficulty, check))		
		end

		protected
		def apply_modifiers(attr_name, value)
			attr_name = attr_name.to_sym if !(attr_name.is_a? Symbol)
			if @modifiers.kind_of? Hash and 
				@modifiers.has_key?(attr_name) and 
				@modifiers[attr_name].kind_of? Array then

				@modifiers[attr_name].each{|mod| value = mod.call(value)}
			end
			value
		end
	end
end