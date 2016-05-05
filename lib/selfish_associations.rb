require 'selfish_associations/base'
require 'selfish_associations/builder'
require 'selfish_associations/path_merger'
require 'selfish_associations/scope_reader'
require 'selfish_associations/selfish_exception'
require 'selfish_associations/association_traverser'
require 'selfish_associations/associations/association'
require 'selfish_associations/associations/has_one'
require 'selfish_associations/associations/has_many'

ActiveRecord::Base.include(SelfishAssociations::Base)
