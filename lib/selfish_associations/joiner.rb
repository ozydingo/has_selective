# A SelfishAssociations::Joiner allows us to define scoped associations that
# can match the association based on instance-level attributes of the model
# We use the same syntax as ActiveRecord scoped assocaitions, with a single
# argument to the scope lambda that represents any given instance. From this
# lambda we can created either a single query (for an instance method) or
# an Arel join (for a class-level joins / query method) that generates the correct
# SQL for matching across the specified attributes
#
# For example
# 
# class Foo
#   has_one_selective :bar, ->(f){where language_id: f.language_id}
# end
#
# You can test these out by using:
# j1 = SelfishAssociations::Joiner.new(TransriptionService, AsrTranscript)
# j1.apply_scope(->(s){where media_file_id: s.media_file_id, language_id: s.media_file.language_id})
# j1.joins_asset.to_sql
# j2 = SelfishAssociations::Joiner.new(TransriptionService.last, AsrTranscript)
# j2.apply_scope(->(s){where media_file_id: s.media_file_id, language_id: s.media_file.language_id})
# j2.find_asset
#
# Under the hood
#
# In order to interpret this lambda, we need to the methods :where and :create_with that will
# yield useful behavior. Most of this useful behavior is defined in the
# SelfishAssociations::AssociationTraverser model. We only then need to define :where to
# send an AssetionAssociationTraverser to the input argument of the scopes defined above, then
# map the resulting Arel::Node value outputs into either a conditions Hash (for a single
# instance find) or a JOIN statement.
#
# We accomplish this first step using the apply_scope method (see below). We do the interpretation
# of the AssociationTraverser's output using join_asset, find_asset, and find_or_create_asset.

module SelfishAssociations
  class Joiner < Object
    attr_reader :find_conditions, :create_attributes
    attr_reader :joins_for_find, :joins_for_create
    attr_reader :traverser

    def initialize(object, foreign_class)
      @klass = object.is_a?(Class) ? object : object.class
      @instance = object.is_a?(Class) ? nil : object
      @klass < ::ActiveRecord::Base or raise ArgumentError, "Cannot initialize an Joiner for #{@klass}"
      @foreign_class = foreign_class
      @reader = SelfishAssociations::ScopeReader.new(@klass)
    end

    def inspect
      "#<#{self.class} for #{@instance || @klass}>"
    end

    # This is the direct interface to a SelfishAssociations::Joiner
    # Use joiner.apply_scope for each scope lambda that you wish to use
    # to add constrainst to the selective join
    def apply_scope(scope)
      @reader.read(scope)
    end

    # Once a joiner is initailized and has its scopes applied, you can
    # use the join & find methods to execute the specified join or find
    def joins_selective
      @find_conditions.present? or raise "No conditions specified! Have you tried using apply_scope yet?"
      conditions = arelize_conditions(@find_conditions)
      arel_join = @klass.arel_table.join(@foreign_class.arel_table).on(conditions).join_sources
      join_with_conditions.joins(arel_join).merge(@foreign_class.all)
    end

    def find_selective
      @foreign_class.find_by(instance_conditions(@find_conditions))
    end

    def find_or_create_selective
      @foreign_class.create_with(instance_conditions(@create_attributes)).find_or_create_by(instance_conditions(@find_conditions))
    end

    def where_selective
      @foreign_class.where(instance_conditions(@find_conditions))
    end

    private

    def join_with_conditions
      @klass.joins(PathMerger.new(@joins_for_find).merge)
    end

    # Convert Traverser Node Hash-syntax conditions (from `where`s) into Arel conditions
    # on the corresponding fields of the model and the specified associations
    def arelize_conditions(conditions)
      conditions.map do |foreign_field, node|
        @foreign_class.arel_table[foreign_field].eq(node)
      end.reduce{|c1, c2| c1.and(c2)}
    end

    # Convert Traverser Node Hash-syntax conditions (from `where`s) into a static
    # Hash of conditions values that can be used directly by ActiveRecord
    def instance_conditions(conditions)
      ensure_instance
      # TODO: if no joins, we can just read fields off of @instance
      # TODO: if cached associations exist, we can read fields off those too
      arel_conditions, static_conditions = conditions.partition{|field, value| value.is_a?(::Arel::Attribute)}.map(&:to_h)
      selector = arel_conditions.map{|field, arel| arel.as(field.to_s)}
      record = join_with_conditions.select(selector).find_by(id: @instance.id)
      arel_conditions.keys.each{|k| static_conditions[k] = record[k]}
      return static_conditions
    end

    def ensure_instance
      @instance.present? or raise NoMethodError, "Tried to perform instance conditions on a Class-level Joiner. Try using Joiner.new(instance, foreign_class) instead."
    end

  end
end