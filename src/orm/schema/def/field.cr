# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX::ORM::SchemaField
  # Defines a SQL field.
  macro field(name)
    {% model_class = @type.class.stringify.gsub(/::Schema.class$/, "").id %}
    {% if name.is_a?(TypeDeclaration) %}
      {%
        full_name = "#{model_class}.#{name.var}"
        FIELDS[full_name] = HashLiteral(String, ASTNode).new if FIELDS[full_name].nil?
        FIELDS[full_name] = {
          model:      model_class,
          name:       name.var,
          full_name:  full_name.id,
          rel_name:   "__#{model_class}_#{name.var}",
          type:       name.type,
          type_class: "#{name.type.is_a?(Union) ? "(#{name.type})".id : name.type}.class".id,
          default:    name.value || "nil".id,
        }
      %}

      @{{name.var}} : {{name.type}}{% if name.value %} = {{name.value}}{% end %}
      def {{name.var}} : {{name.type}}
        @{{name.var}}
      end

      def {{name.var}}=(value : {{name.type}})
        @{{name.var}} = value
      end
    {% else %}
      {% raise "#{model_class}: DBX::ORM::Model.field doesn't support " + name.class_name %}
    {% end %}
  end
end
