module SelfishAssociations
  module Associations
    class HasMany < SelfishAssociations::Association
      def find(instance)
        # TODO: just this? In fact, can we just combined this entirely with AR?
        # foreign_class.instance_exec(instance, @scope)
        foreign_class.where(instance_find_conditions(instance))
      end
    end
  end
end