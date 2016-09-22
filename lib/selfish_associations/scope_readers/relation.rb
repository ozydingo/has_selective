# A scope reader is an object that response to scope methods such as `where` and 
# `create_with`. It must return a ScopeReader for each of these methods so that
# these methods can be chained. For it to be useful, these methods must also have
# side effects that can be inspected by a third party.
# 
# For SelfishAssociations, we generally want to support passing a single argument
# to the scope lambda. E.g. `->(record){ where field: record.matching_field }`. In
# order to collect useful information, we may want to pass a special object in place
# of `record`: one that can respond to the same methods that `record` could respond
# to, but in doing so collects information about each call that is being made. This
# is what we are using the `AssociationTraverser` for in `ScopeReaders::Relation`.
# This traverser can respond to relations and field names of the record model.
# Similarly, it returns a modified traverser in respons to this so that those calls
# may also be chained. For more, see association_traverser.rb.

module SelfishAssociations
  module ScopeReaders
    class Relation < BasicObject
      attr_reader :conditions_for_find, :attributes_for_create
      attr_reader :traverser

      def initialize(klass)
        @traverser = ::SelfishAssociations::AssociationTraverser.new(klass)
        @conditions_for_find = {}
        @joins_for_find = []
        @attributes_for_create = {}
        @joins_for_create = []
      end

      def read(scope)
        args = scope.arity == 0 ? [] : [@traverser]
        instance_exec(*args, &scope)
        return self
      end

      # TODO: implement argless where() and not()
      def where(conditions)
        create_with(conditions)
        @conditions_for_find.merge!(conditions)
        @joins_for_find += @traverser.associations!(merge: false)
        @traverser.reset!
        return self
      end

      def create_with(conditions)
        @attributes_for_create.merge!(conditions)
        @joins_for_create += @traverser.associations!(merge: false)
        @traverser.reset!
        return self
      end

      def joins_for_find
        ::SelfishAssociations::PathMerger.new(@joins_for_find).merge
      end

      def joins_for_create
        ::SelfishAssociations::PathMerger.new(@joins_for_create).merge
      end
    end
  end
end