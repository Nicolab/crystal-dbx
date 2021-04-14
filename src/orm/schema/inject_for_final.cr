# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX::ORM::SchemaInjectForFinal
  include DBX::ORM::SchemaRelation
  include DBX::ORM::SchemaField

  # Finish for the final `Schema` class.
  macro orm_schema_inject_for_final
    {% model_class = @type.class.stringify.gsub(/::Schema.class$/, "").id %}
    {% model_relations = {} of Symbol => ASTNode %}

    {% for path, dec in RELATIONS %}
      {% if model_class == dec[:from_model] %}
        {% model_relations[path] = dec %}
      {% end %}
    {% end %}

    {% consts = @type.constants.map(&.symbolize) %}
    {% unless consts.includes?(:DBValue) %}
      alias DBValue = DBX::QueryBuilder::DBValue
    {% end %}

    # Returns model table name.
    def self.table_name : String
      model_class.table_name
    end

    # Returns model class.
    def self.model_class : {{model_class}}.class
      {{ model_class }}
    end

    {% for full_name, dec in FIELDS %}
      {% if dec[:model] == model_class %}
        @@fields[{{full_name}}] = {
          name: "{{dec[:name]}}",
          rel_name: {{dec[:rel_name]}},
          sql: "#{table_name}.{{dec[:name]}}",
          rel_sql: "#{table_name}.{{dec[:name]}} AS {{dec[:rel_name].id}}"
        }
      {% end %}
    {% end %}

    @@sql_fields : String = self.fields.join(",") { |_, f| f[:sql] }
    @@sql_rel_fields : String = self.fields.join(",") { |_, f| f[:rel_sql] }

    # All DB fields of the `{{model_class}}` model.
    alias FieldsDef = {
      {% for full_name, dec in FIELDS %}
        {% if dec[:model] == model_class %}
          {{dec[:name]}}: { type: {{dec[:type_class]}} },
        {% end %}
      {% end %}
    }

    # --------------------------------------------------------------------------

    # Creates a new `{{model_class}}` instance.
    # > Useful to create (insert) a new entry in the DB.
    def initialize(
      {% for full_name, dec in FIELDS %}
        {% if dec[:model] == model_class %}
          @{{dec[:name]}} : {{dec[:type]}} = {{dec[:default]}},
        {% end %}
      {% end %}
    )
    end

    # Creates a new _strict_ `{{model_class}}` instance without using default value.
    # > Can be populated with data from the DB.
    def self.new_strict(
      {% args = [] of ASTNode %}
      {% for full_name, dec in FIELDS %}
        {% if dec[:model] == model_class %}
          {{dec[:name]}} : {{dec[:type]}},
          {% args << dec[:name] %}
        {% end %}
      {% end %}
    )
      {{model_class}}::Schema.new({{args.splat}})
    end

    private def self.process_next_rel(
      rs : DB::ResultSet,
      relations : Array(RelationDef),
      schema : {{model_class}}::Schema,
      rel_idx : Int32,
      cols_readed : Int32
    )
      next_rel = relations[rel_idx]

      case next_rel[:name]
        {% for path, dec in model_relations %}
          {% if model_class == dec[:from_model] %}
            when {{dec[:name]}}
              {{"last_#{dec[:model_class]}_schema".downcase.id}} : {{dec[:model_class]}}::Schema? = nil

              {% if dec[:has_many] %}
                {{"last_#{dec[:model_class]}_schema".downcase.id}} = schema.{{dec[:name].id}}.last?
              {% end %}

              if rel_schema = {{dec[:model_class]}}::Schema.from_rs(
                rs,
                relations,
                rel_idx + 1, # move cursor to next rel
                cols_readed,
                {{"last_#{dec[:model_class]}_schema".downcase.id}},
              )
                schema.{{dec[:name].id}} {{ dec[:has_one] ? "=".id : "<<".id }} rel_schema.as({{dec[:model_class]}}::Schema)
              end
          {% end %}
        {% end %}
      else
        raise DBX::Error.new %(Cannot resolve the relation "#{next_rel[:model_class]}.#{next_rel[:name]}")
      end
    end

    # Creates an instance from a relation.
    def self.from_rs(
      rs : DB::ResultSet,
      relations : Array(RelationDef),
      rel_idx : Int32 = 0,
      cols_readed : Int32 = 0,
      last_schema : {{model_class}}::Schema? = nil,
    ) : Schema?
      if relations.size == 0
        raise DBX::Error.new "Bad method call. This method must be called only for a query with relation(s)."
      end

      cols_total = rs.column_count

      {% cols_readed_initial = 0 %}

      # Fix: PG::ResultSet#read returned a String. A (Int64 | Nil) was expected.
      # Prevent this error when a resource is found without its relation(s) (like a conventional LEFT JOIN).
      should_not_read_first_field = false

      # first iter or try to check with pk for deep iter
      if !last_schema || cols_readed == 0 || {{model_class}}.pk_name == rs.column_name(cols_readed)
        first_field = rs.read
        should_not_read_first_field = true
        {% cols_readed_initial += 1 %}
        return nil if first_field.nil?
      end

      schema = {{model_class}}::Schema.new_strict(
        {% for full_name, dec in FIELDS %}
          {% if dec[:model] == model_class %}
          {{dec[:name]}}: if should_not_read_first_field
              should_not_read_first_field = false
              first_field.as({{dec[:type]}})
            else
              rs.read({{dec[:type]}})
            end,
          {% cols_readed_initial += 1 %}
          {% end %}
        {% end %}
      )

      # avoid duplicate for deep iteration(s)
      if !last_schema.nil? && last_schema._ukey == schema._ukey
        schema = last_schema
      end

      cols_readed += {{cols_readed_initial}}

      if rel_idx + 1 <= relations.size
        self.process_next_rel(rs, relations, schema, rel_idx, cols_readed)
        return schema
      end

      return schema if cols_total == cols_readed
      schema
    end

    # --------------------------------------------------------------------------

    def self.fields_def : FieldsDef
      {
      {% for full_name, dec in FIELDS %}
        {% if dec[:model] == model_class %}
          {{dec[:name]}}: { type: {{dec[:type]}} },
        {% end %}
      {% end %}
      }
    end

    def self.relations_def : Hash(String, RelationDef)
      @@relations_def
    end

    def self.add_relation(path : String | Symbol, dec : RelationDef) : Schema.class
      full_path = "{{model_class}}.#{path}"

      if @@relations_def.has_key?(full_path)
        raise DBX::Error.new %(relation "#{full_path}" already defined)
      end

      @@relations_def[full_path] = dec
      self
    end

    # Lookup the path in relations def.
    def self.lookup_relation_def?(path : Symbol | String) : {String, RelationDef?}
      model_name = "#{model_class}"
      path = path.to_s
      cursor_path = "#{model_name}.#{path}"

      if rel_found = @@relations_def[cursor_path]?
        return { cursor_path, rel_found }
      end

      path_a = path.split(".")

      # not found above
      return {cursor_path, nil} if path_a.size == 1

      # lookup the rest
      cursor_path = "#{model_name}.#{path_a.first}"
      path_a.size.times do |i|
        next_part_i = i + 1

        if rel_found = @@relations_def["#{cursor_path}"]?
          cursor_path = "#{rel_found[:model_class]}.#{path_a[next_part_i]}"
        end

        # if end of search
        break rel_found if path_a.size == next_part_i + 1
      end

      {cursor_path, rel_found}
    end

    # Find a relation from its path.
    def self.find_relation_from_path(path : String) : {
      relation: RelationDef,
      cursor_path: String,
      field: String,
      model: DBX::ORM::Model.class
    }
      raise DBX::Error.new "Relation path is empty" if path.empty?
      cursor_path, relation_def = self.lookup_relation_def?(path)

      # r_model is the rel_model if the path is not deep, ref_model for deep path
      unless relation_def && (r_model = relation_def[:model_class])
        parts = path.split('.')

        if parts.size > 2
          raise DBX::Error.new %(
            Relation path to long: "#{path}".
            The depth of a relationship selection cannot exceed 2 levels (max is "#{parts[...-1].join(".")}").
            PR is welcome ;-\)
          )
        end

        raise DBX::Error.new %(Undefined relation "#{path}")
      end

      parts = path.split('.')

      # if not deep
      if parts.size == 1
        return { relation: relation_def, cursor_path: cursor_path, field: path, model: r_model }
      end

      ref_model = r_model
      rel_field = parts.last

      {% i = 0 %}
      {% cond_start = "if".id %}
      {% for path, dec in RELATIONS %}
        {% i += 1 %}
        {% if i != 1 %}
          {% cond_start = "elsif".id %}
        {% end %}

        # if the model referant is found
        {{cond_start}} ref_model == {{dec[:from_model]}} && {{dec[:name]}} == rel_field
          # relation model is resolved
          rel_model = {{dec[:model_class]}}

          relation_def = {
            name: {{dec[:name]}},
            model_class: {{dec[:model_class]}},
            has_one: {{dec[:has_one]}},
            has_many: {{dec[:has_many]}}
          }
      {% end %}
        {% if i > 0 %}{{"end".id}}{% end %} # end: cond_start

      raise DBX::Error.new %(Model not found for relation path: "#{path}") unless rel_model

      { relation: relation_def, cursor_path: cursor_path, field: rel_field, model: rel_model }
    end
  end
end
