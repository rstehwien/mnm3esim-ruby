class SuperStruct < Struct
	  # Overwrites the standard Struct initializer
	  # to add the ability to create an instance from a Hash of parameters
	  # and pass a block to yield on self.
	  #
	  #   SuperHero = SuperStruct.new(:name, :nickname)
	  #
	  #   attributes = { :name => "Fred", :nickname => "SuperFred" }
	  #   SuperHero.new(attributes)
	  #   # => #<struct SuperHero name="Fred", nickname="SuperFred">
	  #
	  #   SuperHero.new do |s|
	  #     s.name = "Fred"
	  #     s.nickname = "SuperFred"
	  #   end
	  #   # => #<struct SuperHero name="Fred", nickname="SuperFred">
	  #
	  def initialize(*args, &block)
	    if args.first.is_a? Hash
	      initialize_with_hash(args.first)
	    else
	      super
	    end
	    yield(self) if block_given?
	  end

    def initialize_with_hash(attributes = {})
      attributes.each do |key, value|
        self[key] = value
      end
    end
	  
	end