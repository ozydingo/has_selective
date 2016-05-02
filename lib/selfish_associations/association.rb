module SelfishAssociations
  class Association
    def initialize(name, model, scope, options = {})
      options = options.symbolize_keys!
      @name = name.to_s
      @model = model
      @scope = scope
      @foreign_class_name = (options[:class_name] || name.to_s.classify).to_s

      validate

      @reader = SelfishAssociations::ScopeReader.new(@model)
      add_scope(@scope) if @scope.present?
    end

    def foreign_class
      @foreign_class ||= self.class.const_get(@foreign_class_name)
    end

    def add_scope(scope)
      @reader.read(scope)
    end

    def joins
      conditions = arelize_conditions(@reader.conditions_for_find)
      arel_join = @model.arel_table.join(foreign_class.arel_table).on(conditions).join_sources
      @model.joins(joins_for_find).joins(arel_join).merge(foreign_class.all)
    end

    def find(instance)
      foreign_class.find_by(instance_find_conditions(instance))
    end

    def create(instance)
      foreign_class.create(instance_create_attributes(instance))
    end

    def matches(instance)
      foreign_class.where(instance_find_conditions(instance))
    end


    private

    def arelize_conditions(conditions)
      conditions.map do |foreign_field, node|
        foreign_class.arel_table[foreign_field].eq(node)
      end.reduce{|c1, c2| c1.and(c2)}
    end

    def instance_find_conditions(instance)
      instance_conditions(instance, @reader.conditions_for_find)
    end

    def instance_create_attributes(instance)
      instance_find_conditions(instance).merge(instance_conditions(instance, @reader.attribuets_for_create))
    end

    def joins_for_find
      @reader.joins_for_find
    end

    def joins_for_create
      @reader.joins_for_create
    end

    # TODO: does this even work for create??
    def instance_conditions(instance, conditions)
      # TODO: if no joins, we can just read fields off of instance
      # TODO: if cached associations exist, we can read fields off those too
      arel_conditions, static_conditions = conditions.partition{|field, value| value.is_a?(::Arel::Attribute)}.map(&:to_h)
      selector = arel_conditions.map{|field, arel| arel.as(field.to_s)}
      record = @model.joins(joins_for_find).select(selector).find_by(id: instance.id)
      arel_conditions.keys.each{|k| static_conditions[k] = record[k]}
      return static_conditions
    end

    def validate
      # self.class.const_defined?(foreign_class) or raise SelfishAssociations::SelfishException, "No class named #{foreign_class} found."
      @scope.nil? || @scope.is_a?(Proc) or raise SelfishAssociations::SelfishException, "Scope must be a Proc"
      @model.is_a?(Class) && @model < ActiveRecord::Base or raise SelfishAssociations::SelfishException, "Tried to define a SelfishAssociation for an invalid object (#{@model})"
    end
  end
end