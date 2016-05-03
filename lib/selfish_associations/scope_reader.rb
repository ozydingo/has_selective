# A SelfishAssociations::ScopeReader is responsible for reading a scope lambda, such
# as `->(foo){ where language_id: foo.language_id}`. The reader collects information
# about the scope in order to apply it either to an instnace-level find, e.g., 
# `where(language_id: 1)`, or to a joins, e.g., `where("language_id = foos.language_id")
# It does this by responding to `where` and `create_with` methods that you might
# use in a scope and keeping track of the resulitng Arel Nodes in order to build
# the find or joins query, using an SelfishAssociations::AssociationTraverser to interpret
# the conditions themselves.

module SelfishAssociations
  class ScopeReader < BasicObject
    attr_reader :traverser

    def initialize(klass)
      @traverser = ::SelfishAssociations::AssociationTraverser.new(klass)
      @conditions_for_find = {}
      @joins_for_find = []
      @attribuets_for_create = {}
      @joins_for_create = []
    end

    def read(scope)
      args = scope.arity == 0 ? [] : [@traverser]
      instance_exec(*args, &scope)
    end

    def where(conditions)
      @conditions_for_find.merge!(conditions)
      @joins_for_find += @traverser.associations!(merge: false)
      @traverser.reset!
      return self
    end

    def create_with(conditions)
      @attribuets_for_create.merge!(conditions)
      @joins_for_create += @traverser.associations!
      @traverser.reset!
      return self
    end

    attr_reader :conditions_for_find, :attribuets_for_create

    def joins_for_find
      ::SelfishAssociations::PathMerger.new(@joins_for_find).merge
    end

    def joins_for_create
      ::SelfishAssociations::PathMerger.new(@joins_for_create).merge
    end

    # TODO: implement `.where.not`
    # TODO: join to other SelfishAssociations associations

  end
end