# A SelfishAssociation::Association is the main engine behind generating SelfishAssociations.
# They are primarily defined using the has_one_selfish, has_many_selfish methods.
# But if you want to debug and explor, you can initailize a SelfishAssociation::Association
# easily with a name and a model (class), options scope and other options.
#
#   assoc = SelfishAssociations::Association.new(:native_transcript, Video, ->(vid){where language_id: vid.language_id}, class_name: "Transcript")
#
# Use the :joins, :find, :create, and :matches methods to play!

module SelfishAssociations
  class Association
    def initialize(name, model, scope = nil, options = {})
      options = options.symbolize_keys
      @name = name.to_s
      @model = model
      @foreign_class_name = (options[:class_name] || name.to_s.classify).to_s
      @foreign_key = options[:foreign_key] == false ? false : (options[:foreign_key] || @model.name.foreign_key).to_sym
      @scopes = []

      add_scope(scope) if scope.present?
      add_scope(foreign_key_scope) if @foreign_key.present?
      validate
    end

    def inspect
      "#<#{self.class}:#{self.object_id} @name=#{@name} @model=#{@model} @foreign_class=#{foreign_class} @foreign_key=#{@foreign_key}>"
    end

    def foreign_class
      @foreign_class ||= self.class.const_get(@foreign_class_name)
    end

    def join
      conditions = arelize_conditions(relation_reader.conditions_for_find)
      arel_join = @model.arel_table.join(foreign_class.arel_table).on(conditions).join_sources
      @model.joins(joins_for_find).joins(arel_join).merge(foreign_class.all)
    end

    def matches_for(instance)
      foreign_class.where(instance_find_conditions(instance))
    end

    def initialize_for(instance)
      foreign_class.new(instance_create_attributes(instance))
    end

    def create_for(instance)
      foreign_class.create(instance_create_attributes(instance))
    end

    private

    def add_scope(scope)
      @scopes << scope
    end

    def apply_scopes(reader)
      @scopes.each{|scope| reader.read(scope) }
      return reader
    end

    def arelize_conditions(conditions)
      conditions.map do |foreign_field, node|
        foreign_class.arel_table[foreign_field].eq(node)
      end.reduce(&:and)
    end

    def instance_find_conditions(instance)
      read_instance_find_conditions(instance)
      # TODO: dynamically determine if we should use lookup_instance_find_conditions instead
      # cannot use if the scope constains non-associations
      # should not use if all associations are preloaded on instance
      # cannot use if instance contains unpersisted changes
    end

    def relation_reader
      @relation_reader ||= apply_scopes(SelfishAssociations::ScopeReaders::Relation.new(@model))
    end

    def instance_reader(instance)
      apply_scopes(ScopeReaders::Instance.new(instance))
    end

    def read_instance_find_conditions(instance)
      instance_reader(instance).attributes_for_find
    end

    def read_instance_create_attributes(instance)
      instance_reader(instance).attributes_for_create
    end

    def lookup_instance_find_conditions(instance)
      instantiate_conditions(instance, relation_reader.conditions_for_find)
    end

    def lookup_instance_create_attributes(instance)
      instantiate_conditions(instance, relation_reader.attributes_for_create)
    end

    def instantiate_conditions(instance, conditions)
      arel_conditions, static_conditions = conditions.partition{|field, value| value.is_a?(::Arel::Attribute)}.map(&:to_h)
      selector = arel_conditions.map{|field, arel| arel.as(field.to_s)}
      instance = @model.joins(joins_for_find).select(selector).find_by(id: instance.id)
      arel_conditions.keys.each{|k| static_conditions[k] = instance[k]}
      return static_conditions
    end

    def joins_for_find
      relation_reader.joins_for_find
    end

    def joins_for_create
      relation_reader.joins_for_create
    end

    def foreign_key_scope
      # TODO: pass foreign_key in rather than using the closure
      foreign_key = @foreign_key
      return ->(obj){ where foreign_key => obj.id }
    end

    def validate
      @scopes.each do |scope|
        scope.is_a?(Proc) or raise SelfishAssociations::SelfishException, "Scope must be a Proc"
        scope.arity == 0 || scope.arity == 1 or raise SelfishAssociations::SelfishException, "Scope must have arity of 0 or 1"
      end
      @model.is_a?(Class) && @model < ActiveRecord::Base or raise SelfishAssociations::SelfishException, "Tried to define a SelfishAssociation for an invalid object (#{@model})"
    end
  end
end