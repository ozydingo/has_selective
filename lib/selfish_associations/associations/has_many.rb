module SelfishAssociations
  module Associations
    class HasMany < SelfishAssociations::Association
      def find(instance)
        matches_for(instance)
      end
    end
  end
end