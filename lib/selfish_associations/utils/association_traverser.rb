# A SelfishAssociations::Traverser allows you to explore an ActiveRecord's associations
# You can call any method on an Traverser that is a valid association or column
# name of the initialized class. For associations, the return value is another
# Traverser for the new node, allowing you to iterate this process. For a column
# name, the return values is an Arel::Node representing the endpoint of the traverse.
#
# E.g., for a class Foo that has_one :bar, where Bar has_one :baz
# t = AssociationTraverser.new(Foo)
# t.bar.baz.id
# # => Arel::Attribute(table: "bazs", field: "id")
#
# As a Traverser gets iterated accross associations, it collects every model that
# it has seen.  You can then call :associations! to fetch these associations.
#
# e.g., continuing from above
# # t.associations!
# # => {:bar => :baz}
#
# A Traverser keeps track of all paths it traversed, and each terminal node gets returned
# as an Arel Node. Thus you can use it in a series of calls to return the Arel Nodes, and
# you can subsequently call :associations! on the Traverser to gain access to all
# paths specified by the Hash:
#
# t = AssociationTraverser.new(Foo)
# {baz_id: t.bar.baz.id, quz_name: t.bar.qux.name}
# => {baz_id: #<Arel::Attributes(table: "bazs", name: "id")>, quz_name: <#Arel::Attributes(table: quxes, name: "name")>}
# t.associations!
# {:bar => [:baz, :qux]}
#
# You can also pass merge: false to :associations! to  return associations as an unflattened Array:
# t.associations!(merge: false)
# [[:bar, :baz], [:bar, :qux]]


# We use bang method names to avoid conflicting with valid association and column names
module SelfishAssociations
  class AssociationTraverser < BasicObject
    def initialize(klass)
      klass.is_a?(::Class) or ::Kernel.raise ::ArgumentError, "Input must be a Class"
      @original = klass
      @associations = []
      reset!
    end

    def reset!
      @path = []
      @klass = @original
    end

    # Return associations traversed
    # Default behavior is to return an array of each path (Array of associations)
    # Use argument merge = true to return a Hash where duplicate keys are merged
    def associations!(merge: true)
      merge ? PathMerger.new(@associations).merge : @associations
    end

    # Method Missing pattern (reluctantly).
    # Really we could initialize anew at each node and pre-define all methods
    # But this actually seems more lightweight.
    # Intercept any method to check if it is an association or a column
    # If Association, store current node and iterate to the association.
    # If it is a column, return an Arel::Node representing that value
    # Else, raise NoMethodError
    def method_missing(method, *args)
      if @klass.column_names.include?(method.to_s)
        @associations << @path if @path.present?
        node = @klass.arel_table[method]
        reset!
        return node
      elsif @klass.reflect_on_association(method)
        @path << method
        @klass = @klass.reflect_on_association(method).klass
        return self
      elsif @klass.selfish_associations[method].present?
        @path << method
        @klass = @klass.selfish_associations[method].foreign_class
        return self
      else
        message = "No association or field named #{method} found for class #{@klass}"
        reset!
        ::Kernel.raise ::NoMethodError, message
      end
    end
  end
end