module SelfishAssociations
  class Builder
    def initialize(model)
      @model = model
    end

    def initialize_methods_class
      @model.const_set("SelfishAssociationMethods", Module.new) unless defined? @model::SelfishAssociationMethods
      @model.include @model::SelfishAssociationMethods if !@model.ancestors.include?(@model::SelfishAssociationMethods)
    end

    def add_association(name, assoc)
      initialize_methods_class
      @model.selfish_associations[name] = assoc

      @model::SelfishAssociationMethods.class_eval do
        define_method(name) do |reload = false|
          return @selfish_association_cache[name] if !reload && @selfish_association_cache.key?(name)
          @selfish_association_cache[name] = self.selfish_associations[name].find(self)
        end
      end
    end
  end
end