# A SelfishAssociation::Association is the main engine behind generating SelfishAssociations.
# They are primarily defined using the has_one_selfish, has_many_selfish methods.
# Similar to ActiveRecord Associations, they require a name, and a model. They can
# also take an optional scope. Like ActiveRecord Associations, this scope can take
# an argument that, in instance context, will take the instance value. The key feature
# of SelfishAssociations is that in Relation context (e.g. for joins), the argument
# will represent the model's table. This allows you to define an association such as
#
#   has_one :same_language_transcript, ->(video){ where language_id: video.language_id }, class_name: "Transcript"
#
# that will correctly work in a joins: Video.joins(same_language_transcript)
#
#   Video.joins(:same_language_transcript).to_sql
#   # => "SELECT * FROM videos LEFT JOIN transcripts ON transcripts.video_id = videos.id AND transcripts.language_id = videos.langauge_id"
#
# Because of this approach, you can in fact leave off the foreign_key constaint and
# the internal engine will not constrain the query on transcripts to have video_id
# matching the caller's id
#
# has_one :any_same_language_transcript, ->(video){ where language_id: video.language_id }, class_name: "Transcript", foreign_key: false
# 
#   Video.joins(:same_language_transcript).to_sql
#   # => "SELECT * FROM videos LEFT JOIN transcripts ON transcripts.language_id = videos.langauge_id"
#
# This ability is most useful when you have other identifying constraints that for
# whatever reason are not defined as an ActiveRecord Association, e.g.:
#   has_one :any_same_language_transcript, ->(video){ where external_id: video.external_id, language_id: video.language_id }, class_name: "Transcript", foreign_key: false
# Of course, in this case for example, you may want to consider adding more standard
# assoication by adding video_id to the transcripts table. But the power is yours.


module SelfishAssociations
  class Association
    def initialize(name, model, scope = nil, options = {})
      options = options.symbolize_keys
      @name = name.to_s
      @model = model
      @scope = scope
      @foreign_class_name = (options[:class_name] || name.to_s.classify).to_s
      @foreign_key = options[:foreign_key] == false ? false : (options[:foreign_key] || @model.name.foreign_key).to_sym

      validate

      @reader = SelfishAssociations::ScopeReader.new(@model)
      # Can't use ivar inside Lambda
      foreign_key = @foreign_key
      add_scope(->(selph){ where foreign_key => selph.id }) if @foreign_key.present?
      add_scope(@scope) if @scope.present?
    end

    def inspect
      "#<#{self.class}:#{self.object_id} @name=#{@name} @model=#{@model} @foreign_class=#{foreign_class} @foreign_key=#{@foreign_key}>"
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