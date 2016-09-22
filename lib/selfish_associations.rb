require 'selfish_associations/base'
require 'selfish_associations/builder'
require 'selfish_associations/selfish_exception'
require 'selfish_associations/utils/association_traverser'
require 'selfish_associations/utils/nilifier'
require 'selfish_associations/utils/path_merger'
require 'selfish_associations/scope_readers/instance'
require 'selfish_associations/scope_readers/relation'
require 'selfish_associations/associations/association'
require 'selfish_associations/associations/has_one'
require 'selfish_associations/associations/has_many'

ActiveRecord::Base.include(SelfishAssociations::Base)
