module SelfishAssociations
  module Associations
    class HasOne < SelfishAssociations::Association
      def find(instance)
        # TODO: just this? In fact, can we just combined this entirely with AR?
        # foreign_class.instance_exec(instance, @scope).first
        foreign_class.find_by(instance_find_conditions(instance))
      end
    end
  end
end