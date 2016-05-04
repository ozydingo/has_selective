# Extends ActiveRecord::Base by adding a has_one_selfish (and, eventually, has_many_selfish)
# class method to define SelfishAssociations.

module SelfishAssociations
  module SelfishAssociationMethods
  end
end

ActiveRecord::Base.include(SelfishAssociations::Base)

require_relative 'selfish_associations/association_traverser'
require_relative 'selfish_associations/association'
require_relative 'selfish_associations/path_merger'
require_relative 'selfish_associations/scope_reader'
require_relative 'selfish_associations/selfish_exception'