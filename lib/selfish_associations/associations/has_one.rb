module SelfishAssociations
  module Associations
    class HasOne < SelfishAssociations::Association
      def find(instance)
        matches_for(instance).first
      end
    end
  end
end