module SelfishAssociations
  class Nilifier < BasicObject
    def initialize(object)
      @object = object
    end

    def inspect
      @object.inspect + " (nil-safe)"
    end

    def unnilify
      @object
    end

    def respond_to?(method)
      true
    end

    def method_missing(method, *args)
      result = @object.respond_to?(method) ? @object.public_send(method, *args) : nil
      ::SelfishAssociations::Nilifier.new(result)
    end
  end
end
