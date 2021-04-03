# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX::ORM::SchemaRelation
  macro relation(var_decl, **opt)
    {% model_class = @type.class.stringify.gsub(/::Schema.class$/, "").id %}
    {% if var_decl.is_a?(TypeDeclaration) %}
      {%
        if var_decl.type.stringify.starts_with?("Array")
          rel_model = var_decl.type.stringify[6...-1].id # remove Array()
          rel_schema_type = "Array(#{rel_model}::Schema)".id
          has_one = false
          has_many = true
        else
          rel_model = var_decl.type
          rel_schema_type = "#{rel_model}::Schema".id
          has_one = true
          has_many = false
        end
      %}

      unless {{var_decl.type}}.is_a?(DBX::ORM::Model.class) || {{rel_model}}.is_a?(DBX::ORM::Model.class)
        raise "{{model_class}}: relation must be a Model class but is a {{var_decl.type}}"
      end

      {%
        RELATIONS["#{model_class}.#{var_decl.var}"] = {
          name:        "#{var_decl.var}",
          model_class: rel_model,
          from_model:  model_class,
          has_one:     has_one,
          has_many:    has_many,
        }
      %}

      self.add_relation("{{var_decl.var}}", {
        name: "{{var_decl.var}}",
        model_class: {{rel_model}},
        has_one: {{has_one}},
        has_many: {{has_many}},
      })

      @[JSON::Field(emit_null: false)]
      @[DB::Field(ignore: true)]
      @{{var_decl.var}} : {{rel_schema_type}}?

      def {{var_decl.var}} : {{rel_schema_type}}{% if has_one %}?{% end %}
        {% if has_many %}
          @{{var_decl.var}} = [] of {{rel_model}}::Schema unless @{{var_decl.var}}
          return @{{var_decl.var}}.not_nil!
        {% end %}

        @{{var_decl.var}}
      end

      def {{var_decl.var}}=(value : {{rel_schema_type}})
        @{{var_decl.var}} = value
      end
    {% else %}
      {% raise "#{model_class}: DBX::ORM::Model.relation doesn't support #{var_decl.class_name}" %}
    {% end %}
  end
end
