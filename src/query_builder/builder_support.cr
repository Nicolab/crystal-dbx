# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX
  class QueryBuilder
    macro finished
      {% consts = @type.constants.map(&.symbolize) %}
      {% unless consts.includes?(:DBValue) %}
        # DB Value.
        alias DBValue = DB::Any | UUID

        # Argument(s) for SQL query.
        alias ArgsType = Enumerable(DBValue)

        # The return type of `build` method.
        alias SQLandArgsType = Tuple(String, ArgsType)

        # The type of the data `Hash`,
        # used as a KV container for insert and update.
        alias DataHashType = Hash(FieldType, DBValue)

        @data : DataHashType?
      {% end %}

      {% unless consts.includes?(:QUOTE) %}
        # Quoting character.
        QUOTE = '"'
      {% end %}
    end

    # Placeholder for SQL argument(s).
    @placeholder = "?"

    # Wraps *field* with quotes (`QUOTE`).
    def quote(field : FieldType) : String
      "#{QUOTE}#{field}#{QUOTE}"
    end

    # Adds placeholder for a SQL argument.
    def ph(position : Int)
      @placeholder
    end

    # Adds value to *args* and returns the `placeholder`.
    def add_arg(value) : String
      value = value.to_s if value.is_a?(Symbol)
      @args << value
      ph(@args.size)
    end

    # Extracts arguments and fields from data, populates `args`
    # and returns SQL part for a listing statement.
    # Example: `field1, field2, field3`
    def add_args_and_fields_from_data(data : NamedTuple | Hash, sep = ", ") : String
      data.map { |_, value| add_arg(value) }.join(sep)
    end

    # :ditto:
    def add_args_and_fields_from_data(data : Array, sep = ", ") : String
      data.map { |value| add_arg(value) }.join(sep)
    end

    # Extracts arguments and fields from data, populates `args`
    # and returns SQL part for a combined statement.
    # Example: `field1 = $1, field2 = $2, field3 = $3`
    def add_args_and_kv_from_data(data : NamedTuple | Hash, sep = ", ") : String
      data.map do |field, value|
        "#{quote(field)} = #{add_arg(value)}"
      end.join(sep)
    end
  end
end
