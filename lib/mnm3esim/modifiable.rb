module MnM3eSim
	class ModifiableStructData
		def initialize(args={})
			clear_modifiers
			args.each {|k,v| send("#{k}=",v)}
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

		def respond_to?(meth)
			if modifiable_properties.include?(meth) then
				true
			else
				super
			end
		end

		def modifiable_properties
			dm = (@data.kind_of? Struct) ? @data.class.instance_methods(false) : []
			dm.concat([:roll_d20,:check_degree])
		end

		def method_missing(meth, *args, &block)  
			if modifiable_properties.include?(meth) then
				run_modifiable_properties(meth, *args, &block)
			else
				super
			end 
		end

		def run_modifiable_properties(meth, *args, &block)
			if meth == :roll_d20
				result = run_roll_d20(meth, *args, &block)
			elsif meth == :check_degree
				result = run_check_degree(meth, *args, &block)		
			else
				result = run_data_method(meth, *args, &block)
			end

			if @modifiers.kind_of? Hash and @modifiers.has_key?(meth) and @modifiers[meth].kind_of? Array and !(meth.to_s =~ /$=/) then
				@modifiers[meth].each{|mod| result = mod.call(result)}
			end

			result
		end

		def run_data_method(meth, *args, &block)
			@data.send(meth, *args, &block)
		end

		def run_roll_d20(meth, *args, &block)
			MnM3eBase.send(meth, *args, &block)
		end

		def run_check_degree(meth, *args, &block)
			MnM3eBase.send(meth, *args, &block)
		end
	end
end