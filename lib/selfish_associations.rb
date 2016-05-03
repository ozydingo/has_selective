# Extends ActiveRecord::Base by adding a has_one_selfish (and, eventually, has_many_selfish)
# class method to define SelfishAssociations.

module SelfishAssociations

  module SelfishAssociationMethods
    def reset_selfish_association_cache
      @selfish_association_cache = {}
    end
  end

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

    # TODO: use a :selfish method with a block?
    module ClassMethods
      def has_one_selfish(name, scope = nil, **options)
        const_set("SelfishAssociationMethods", SelfishAssociations::SelfishAssociationMethods.dup) unless defined? self::SelfishAssociationMethods
        include self::SelfishAssociationMethods if !ancestors.include?(self::SelfishAssociationMethods)

        self.selfish_associations[name] = SelfishAssociations::Association.new(name, self, scope, options)

        self::SelfishAssociationMethods.class_eval do
          define_method(name) do |reload = false|
            return @selfish_association_cache[name] if !reload && @selfish_association_cache.key?(name)
            assoc = self.selfish_associations[name] or raise SelfishException, "No selfish_associations named #{name} found, perhaps you misspelled it?"
            @selfish_association_cache[name] = assoc.find(self)
          end
        end
      end

      # NIY
      # def has_many_selfish
      # end

      def selfish_joins(name)
        assoc = self.selfish_associations[name] or raise SelfishException, "No selfish_associations named #{name} found, perhaps you misspelled it?"
        assoc.joins
      end

    end
  end
end

ActiveRecord::Base.include(SelfishAssociations::Base)

require_relative 'selfish_associations/association_traverser'
require_relative 'selfish_associations/association'
require_relative 'selfish_associations/path_merger'
require_relative 'selfish_associations/scope_reader'
require_relative 'selfish_associations/selfish_exception'