module SelfishAssociations
  module Base
    extend ActiveSupport::Concern

    included do
      class_attribute :selfish_associations
      self.selfish_associations = {}
      attr_reader :selfish_association_cache
      after_initialize :reset_selfish_association_cache
    end

    def reset_selfish_association_cache
      @selfish_association_cache = {}
    end

    module ClassMethods
      def has_one_selfish(name, scope = nil, **options)
        SelfishAssociations::Builder.new(self).add_association(name, SelfishAssociations::Associations::HasOne.new(name, self, scope, options))
      end

      def has_many_selfish(name, scope = nil, **options)
        SelfishAssociations::Builder.new(self).add_association(name, SelfishAssociations::Associations::HasMany.new(name, self, scope, options))
      end

      def selfish_joins(name)
        assoc = self.selfish_associations[name] or raise SelfishException, "No selfish_associations named #{name} found, perhaps you misspelled it?"
        assoc.join
      end

    end
  end
end