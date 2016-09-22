module SelfishAssociations
  module ScopeReaders
    class Instance < BasicObject
      attr_reader :attributes_for_find, :attributes_for_create

      def initialize(instance)
        @instance = Nilifier.new(instance)
        @attributes_for_find = {}
        @attributes_for_create = {}
      end

      def read(scope)
        args = scope.arity == 0 ? [] : [@instance]
        instance_exec(*args, &scope)
        return self
      end

      def where(conditions)
        unnilify(conditions)
        create_with(conditions)
        @attributes_for_find.merge!(conditions)
        return self
      end

      def create_with(conditions)
        unnilify(conditions)
        @attributes_for_create.merge!(conditions)
        return self
      end

      def unnilify(conditions)
        conditions.keys.each do |key|
          conditions[key] = conditions[key].unnilify if conditions[key].respond_to?(:unnilify?)
        end
      end
    end
  end
end
