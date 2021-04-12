# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX::ORM
  # Generic `ModelQuery` class.
  # > Automatically injected into the models.
  #
  # If you want to customize the queries of a model, you can define
  # you own `ModelQuery` into this model.
  #
  # ```
  # class User < DBX::ORM::Model
  #   # ...
  #
  #   class ModelQuery < DBX::ORM::ModelQuery(User)
  #     # A custom `select`
  #     def select_custom
  #       self.select({:id, :name, :about, :age})
  #     end
  #   end
  # end
  # ```
  #
  # In the model example above, we have added a new method (`select_custom`) to `ModelQuery',
  # which can be used in each query.
  #
  # ```
  # user = User.find(id).select_custom.to_o
  # users = User.find.select_custom.to_a
  # ```
  class ModelQuery(Model) < DBX::Query
    @fields_selected : Bool = false
    @rel_fields_selected : Hash(String, Bool) = {} of String => Bool
    @relations : Array(DBX::ORM::Schema::RelationDef) = Array(DBX::ORM::Schema::RelationDef).new

    # Returns `true` if the model fields are selected, `false` otherwise.
    # See `select_all`
    def selected_all? : Bool
      @fields_selected
    end

    # Selects all SQL fields.
    def select_all : ModelQuery(Model)
      return self if @fields_selected

      self.select(Model::Schema.sql_fields)
      @fields_selected = true
      self
    end

    # Returns `true` if the relation fields are selected, `false` otherwise.
    # See `select_rel_fields`
    def selected_all?(model_class : DBX::ORM::Model.class, table_alias : String | Symbol | Nil = nil) : Bool
      @rel_fields_selected.has_key? "#{model_class}=>#{table_alias}"
    end

    # Selects the relation fields.
    # This method is automatically called by the methods related to the joins with a model class.
    def select_all(model_class : DBX::ORM::Model.class, table_alias : String | Symbol | Nil = nil) : ModelQuery(Model)
      return self if selected_all? model_class, table_alias

      if table_alias
        table_alias = table_alias.to_s
        sql_fields = model_class.schema_class.fields.join(",") { |_, field| "#{table_alias}.#{field[:name]}" }
      else
        sql_fields = model_class.schema_class.sql_fields
      end

      self.select(sql_fields)
      @rel_fields_selected["#{model_class}=>#{table_alias}"] = true
      self
    end

    # --------------------------------------------------------------------------
    # Relations / Ref
    # --------------------------------------------------------------------------

    # Refers to the result of a join in a defined `relation` property path.
    #
    # ```
    # users = User
    #   .find
    #   .rel("groups")
    #   .left_join("groups", "groups.id", "users.group_id")
    #   .to_a
    # ```
    def rel(path : Symbol | String, table_alias : String | Symbol | Nil = nil) : ModelQuery(Model)
      r = Model::Schema.find_relation_from_path(path.to_s)
      @relations << r[:relation]
      select_all.select_all(r[:model], table_alias)
    end

    # def inner_join(model_class : DBX::ORM::Model.class) : ModelQuery(Model)
    #   select_all.select_rel_fields(model_class)

    #   inner_join(
    #     model_class.table_name,
    #     "#{Model.table_name}.#{Model.fk_name.not_nil!}",
    #     "#{model_class.table_name}.#{Model.pk_name}"
    #   )
    #   self
    # end

    # def left_join(model_class : DBX::ORM::Model.class) : ModelQuery(Model)
    #   select_all.select_rel_fields(model_class)

    #   left_join(
    #     model_class.table_name,
    #     "#{Model.table_name}.#{Model.fk_name.not_nil!}",
    #     "#{model_class.table_name}.#{Model.pk_name}"
    #   )
    #   self
    # end

    # --------------------------------------------------------------------------
    # Executors
    # --------------------------------------------------------------------------

    # Creates a new record and returns.
    #
    # ```
    # test = Test.create!(data)
    # puts test.id
    # ```
    def create!(data, returning : DBX::QueryBuilder::OneOrMoreFieldsType = "*")
      create!(
        data,
        as: Model::Schema,
        returning: returning,
        pk_name: Model.pk_name,
        pk_type: Model.pk_type
      )
    end

    # Executes current query using current `Model::Schema`.
    def query_one
      return query_one_with_rel unless @relations.size == 0
      query_one(as: Model::Schema)
    end

    # Executes current query using current `Model::Schema`.
    def query_one!
      return query_one_with_rel! unless @relations.size == 0
      query_one!(as: Model::Schema)
    end

    # Executes current query using current `Model::Schema`.
    def query_all
      return query_all_with_rel unless @relations.size == 0
      query_all(as: Model::Schema)
    end

    # --------------------------------------------------------------------------

    # Shortcut, same as `query_one!`.
    def to_o!
      return query_one_with_rel! unless @relations.size == 0
      query_one!(as: Model::Schema)
    end

    # Shortcut, same as `query_one`.
    def to_o
      return query_one_with_rel unless @relations.size == 0
      query_one(as: Model::Schema)
    end

    # Shortcut, same as `query_one!(types)`.
    def to_o!(as types)
      query_one!(types)
    end

    # Shortcut, same as `query_one(types)`.
    def to_o(as types)
      query_one(types)
    end

    # Shortcut, same as `query_all`.
    def to_a
      return query_all_with_rel unless @relations.size == 0
      query_all(as: Model::Schema)
    end

    # Shortcut, same as `query_all(types)`.
    def to_a(as types)
      query_all(types)
    end

    # --------------------------------------------------------------------------

    # query_one, to_o
    private def query_one_with_rel : Model::Schema?
      res = query_all_with_rel
      raise DB::Error.new "more than one row" if res.size > 1
      res.first?
    end

    # query_one!, to_o!
    private def query_one_with_rel! : Model::Schema
      res = query_one_with_rel
      raise DB::NoResultsError.new "no results" unless res
      res
    end

    # query_all, to_a
    private def query_all_with_rel : Array(Model::Schema)
      res = [] of Model::Schema

      query_all do |rs|
        last_schema = res.last?
        if schema = Model::Schema.from_rs(rs, @relations, last_schema: last_schema)
          res << schema if !last_schema || last_schema._ukey != schema._ukey
        end

        rs
      end

      res
    end
  end
end
