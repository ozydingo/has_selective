module SelfishAssociations

  module SelfishAssociationMethods
    def reset_selfish_association_cache
      @selfish_association_cache = {}
    end
  end

  # module Base
  #   extend ActiveSupport::Concern

  #   included do
  #     class_attribute :selfish_associations
  #     self.selfish_associations = {}
  #     after_initialize :reset_selfish_association_cache
  #   end

  #   # TODO: use a :selfish method with a block
  #   module ClassMethods
  #     def has_one_selfish(assoc, scope = nil, **options)
  #       const_set("SelfishAssociationMethods", SelfishAssociations::SelfishAssociationMethods.dup) unless defined? self::SelfishAssociationMethods
  #       include self::SelfishAssociationMethods if !ancestors.include?(self::SelfishAssociationMethods)

  #       self.selfish_associations[assoc] = SelfishAssociations::Association.new(assoc, self, scope, options)

  #       self::SelfishAssociationMethods.define_method(assoc) do |reload = false|
  #         return @selfish_association_cache[assoc] if @selfish_association_cache.key?(assoc)
  #         @selfish_association_cache[assoc] = nil
  #       end
  #     end

  #     # def has_many_selfish
  #     # end

  #     def selfish_joins(assoc)
  #       self.selfish_associations.key?[assoc] or raise SelfishException, "No selfish_associations named #{assoc} found, perhaps you misspelled it?"
  #       joiner = SelfishAssociations::Joiner.new(self, assoc)
  #       joiner.apply_scope(self.selfish_associations[assoc])
  #     end

  #   end
  # end
end

# ActiveRecord::Base.include(SelfishAssociations::Base)

require_relative 'selfish_associations/association_traverser'
require_relative 'selfish_associations/association'
# require_relative 'selfish_associations/joiner'
require_relative 'selfish_associations/path_merger'
require_relative 'selfish_associations/scope_reader'
require_relative 'selfish_associations/selfish_exception'