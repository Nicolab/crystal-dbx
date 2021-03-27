# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX
  # Query builder.
  class QueryBuilder
    # Field type.
    alias FieldType = String | Symbol

    # The type for several fields contained in an `Enumerable` (e.g: `Array` or `Tuple`).
    alias FieldsType = Enumerable(FieldType) | Enumerable(Symbol) | Enumerable(String)

    # The type for one or more fields.
    alias OneOrMoreFieldsType = FieldType | FieldsType

    @query_method : Symbol?
    @last_query_method : Symbol?
    @returning : String? = nil
    @options : Bool |
               NamedTuple(
      command: String,
      field: String,
      data_type: String) |
               Nil = nil

    {% begin %}
      {% initial_query_vars = <<-VARS
          @query_method = nil
          @query = ""
          @data_kv = ""
          @data = nil
          @options = nil
          @returning = nil
          @args = [] of DBValue
          @select = "*"
          @table = ""
          @join = ""
          @where = ""
          @group_by = ""
          @having = ""
          @order_by = ""
          @limit = ""
          @offset = ""
        VARS
      %}

      # Creates a new `QueryBuilder`.
      def initialize()
        {{ initial_query_vars.id }}
        @operators = ["=", "!=", "<", ">", "<=", ">=", "<>"]
        @query_count = 0
        @last_query_method = nil
        @last_query = ""
      end

      # Resets current query.
      def reset_query
        {{ initial_query_vars.id }}
        nil
      end
    {% end %}

    # Targets one or more tables.
    def table(name : OneOrMoreFieldsType) : QueryBuilder
      @table = name.is_a?(FieldsType) ? name.join(", ") : name.to_s

      self
    end

    # Targets tables defined by variadic arguments.
    #
    # ```
    # builder.table(:table1, :table2)
    # ```
    def table(*name : FieldType) : QueryBuilder
      table(name)
    end

    # Defines in raw form the SQL statement of the table(s).
    # > Be careful, you have to manage arguments (`arg`) and quotes (`q`).
    #
    # Example:
    #
    # ```
    # builder.find { "#{q("posts") AS p, articles a" }"
    # ```
    #
    # Generates:
    #
    # ```
    # SELECT * FROM "posts" AS p, articles a
    # ```
    def table(&block) : QueryBuilder
      @table = with QueryBuilderScope.new(self) yield
      self
    end

    # Returns table name(s). Returns empty string if no table has been defined.
    #
    # ```
    # puts builder.table unless builder.table.blank? # or .empty?
    # ```
    def table : String
      @table
    end

    # Used by `select` and by `returning`.
    private def _build_selected_fields(fields : OneOrMoreFieldsType) : String
      _fields = ""

      if fields.is_a?(String)
        fields.split(",").each { |field|
          _fields = "#{_fields}#{field.strip}, "
        }
      elsif fields.is_a?(FieldsType)
        _fields = ""
        fields.each { |field|
          _fields = "#{_fields}#{field}, "
        }
      else
        _fields = fields.to_s
      end

      if without_last_comma = _fields.rchop?(", ")
        _fields = without_last_comma
      end

      _fields
    end

    # Selects one or more fields.
    def select(fields : OneOrMoreFieldsType) : QueryBuilder
      _fields = _build_selected_fields(fields)
      @select = @select.compare("*") == 0 ? _fields : "#{@select}, #{_fields}"
      self
    end

    # :ditto:
    def select(*name : FieldType) : QueryBuilder
      self.select(name)
    end

    # Returns selected field(s). Default is `*`.
    #
    # ```
    # puts builder.select
    # ```
    def select : String
      @select
    end

    {% for method in %w(min max avg sum count) %}
      # Adds `{{method.upcase.id}}` to the current query.
      def {{method.id}}(field : FieldType, name = nil) : QueryBuilder
        {{method.id}} = "{{method.upcase.id}}(#{field})"
        {{method.id}} += " AS #{name}" unless name.nil?
        @select = @select.compare("*") == 0 ? {{method.id}} : "#{@select}, #{{{method.id}}}"
        self
      end
    {% end %}

    def join(
      table : FieldType,
      field1 : FieldType,
      field2 : FieldType? = nil,
      type = ""
    ) : QueryBuilder
      @join += if field2.nil?
                 " #{type} JOIN #{table} ON #{field1}"
               else
                 " #{type} JOIN #{table} ON #{field1} = #{field2}"
               end
      self
    end

    # Adds a raw `join` to current query.
    # > Be careful, you have to manage arguments (`arg`) and quotes (`q`).
    #
    # Example:
    #
    # ```
    # builder.find("tests").join { "
    #   INNER JOIN T2 ON T1.a = T2.a
    #   AND T1.b = T2.b
    #   OR T1.b = #{q(some_value_to_quote)}
    # " }
    #   .join { "LEFT JOIN payments p USING (product_id)" }
    # ```
    def join(&block) : QueryBuilder
      @join += " #{with QueryBuilderScope.new(self) yield}"
      self
    end

    {% for method in %w(inner full left right full_outer left_outer right_outer) %}
    {% sql_name = method.gsub(/_/, " ").upcase.id %}
      # Adds `{{sql_name}} JOIN` to the current query.
      def {{method.id}}_join(
        table : FieldType,
        field1 : FieldType,
        field2 : FieldType? = nil
      ) : QueryBuilder
        join table, field1, field2, "{{sql_name}}"
      end
    {% end %}

    # Returns jointure. Returns empty string if no jointure has been defined.
    #
    # ```
    # puts builder.join unless builder.join.blank? # or .empty?
    # ```
    def join : String
      @join
    end

    def where(field : FieldType, value = nil, type = "", and_or = "AND") : QueryBuilder
      where(field, value, type, and_or)
    end

    # Where clause.
    def where(field : FieldType, op_or_val, value = nil, type = "", and_or = "AND") : QueryBuilder
      where = if @operators.includes?(op_or_val.to_s)
                " #{type}#{field} #{op_or_val} #{add_arg(value)}"
              else
                " #{type}#{field} = #{add_arg(op_or_val)}"
              end

      @where += @where.empty? ? where : " #{and_or}#{where}"
      self
    end

    # Adds a raw `where` to current query.
    # > Be careful, you have to manage arguments (`arg`) and quotes (`q`).
    #
    # Example:
    #
    # ```
    # builder.find("tests").where { "
    #   status = #{arg(true)}
    #   AND (
    #     #{q(:date)} <= #{arg(Time.utc - 1.day)}
    #     OR role = #{arg(:admin)}
    #   )
    # " }
    # ```
    #
    # Generates:
    #
    # ```text
    # SELECT *
    # FROM tests
    # WHERE status = $1
    # AND ("date" <= $2 OR role = $3)
    # ```
    def where(&block) : QueryBuilder
      @where += " #{with QueryBuilderScope.new(self) yield}"
      self
    end

    def or_where(field : FieldType, op_or_val, value = nil) : QueryBuilder
      where field, op_or_val, value, "", "OR"
    end

    def not_where(field : FieldType, op_or_val, value = nil) : QueryBuilder
      where field, op_or_val, value, "NOT ", "AND"
    end

    def or_not_where(field : FieldType, op_or_val, value = nil) : QueryBuilder
      where field, op_or_val, value, "NOT ", "OR"
    end

    def in(field : FieldType, values : Array | Tuple, type = "", and_or = "AND") : QueryBuilder
      keys = [] of String
      values.each { |val| keys << add_arg(val) }
      @where += if @where.empty?
                  "#{field} #{type}IN (#{keys.join(", ")})"
                else
                  " #{and_or} #{field} #{type}IN (#{keys.join(", ")})"
                end
      self
    end

    def or_in(field : FieldType, values : Array | Tuple) : QueryBuilder
      self.in field, values, "", "OR"
      self
    end

    def not_in(field : FieldType, values : Array | Tuple) : QueryBuilder
      self.in field, values, "NOT ", "AND"
      self
    end

    def or_not_in(field : FieldType, values : Array | Tuple) : QueryBuilder
      self.in field, values, "NOT ", "OR"
      self
    end

    def between(field : FieldType, value1, value2, type = "", and_or = "AND") : QueryBuilder
      @where += if @where.empty?
                  "#{field} #{type}BETWEEN #{add_arg(value1)} AND #{add_arg(value2)}"
                else
                  " #{and_or} #{field} #{type}BETWEEN #{add_arg(value1)} AND #{add_arg(value2)}"
                end
      self
    end

    def or_between(field : FieldType, value1, value2) : QueryBuilder
      between field, value1, value2, "", "OR"
    end

    def not_between(field : FieldType, value1, value2) : QueryBuilder
      between field, value1, value2, "NOT ", "AND"
    end

    def or_not_between(field : FieldType, value1, value2) : QueryBuilder
      between field, value1, value2, "NOT ", "OR"
    end

    def like(field : FieldType, value, type = "", and_or = "AND") : QueryBuilder
      @where += if @where.empty?
                  "#{field} #{type}LIKE #{add_arg(value)}"
                else
                  " #{and_or} #{field} #{type}LIKE #{add_arg(value)}"
                end
      self
    end

    def or_like(field : FieldType, value) : QueryBuilder
      like field, value, "", "OR"
    end

    def not_like(field : FieldType, value) : QueryBuilder
      like field, value, "NOT ", "AND"
    end

    def or_not_like(field : FieldType, value) : QueryBuilder
      like field, value, "NOT ", "OR"
    end

    def limit(limit, limit_end = nil) : QueryBuilder
      if limit_end.nil?
        @limit = add_arg(limit)
      else
        @limit = add_arg(limit_end)
        offset(limit)
      end

      self
    end

    # Returns `limit` value. Returns empty string if no limit has been defined.
    #
    # ```
    # puts builder.limit unless builder.limit.blank? # or .empty?
    # ```
    def limit
      @limit
    end

    def offset(offset) : QueryBuilder
      @offset = add_arg(offset)
      self
    end

    # Returns `offset` value. Returns empty string if no offset has been defined.
    #
    # ```
    # puts builder.offset unless builder.offset.blank? # or .empty?
    # ```
    def offset
      @offset
    end

    # Sets `offset` and `limit` to get pagination-compatible results.
    def paginate(per_page, page) : QueryBuilder
      @limit = add_arg(per_page)
      @offset = add_arg(((page > 0 ? page : 1) - 1) * per_page)
      self
    end

    def order_by(field : FieldType, dir = nil) : QueryBuilder
      field = field.to_s
      order_by = if dir.nil?
                   (field.includes?(" ") || field == "rand()") ? field : "#{field} ASC"
                 else
                   "#{field} #{dir.to_s.upcase}"
                 end

      @order_by += @order_by.empty? ? order_by : ", #{order_by}"
      self
    end

    def group_by(field : OneOrMoreFieldsType) : QueryBuilder
      @group_by = field.is_a?(FieldsType) ? field.join(", ") : field.to_s

      self
    end

    def having(field : FieldType, op_or_val, value = nil) : QueryBuilder
      @having = if @operators.includes?(op_or_val.to_s)
                  "#{field} #{op_or_val} #{add_arg(value)}"
                else
                  "#{field} > #{add_arg(op_or_val)}"
                end
      self
    end

    # Defines in raw form the SQL statement of `HAVING`.
    # > Be careful, you have to manage arguments (`arg`) and quotes (`q`).
    #
    # Example:
    #
    # ```
    # builder.find(:tests).group_by(:payment).having { "SUM(price) > 40" }
    # ```
    #
    # Generates:
    #
    # ```
    # SELECT * FROM "tests" GROUP_BY payment HAVING SUM(person) > 40
    # ```
    def having(&block) : QueryBuilder
      @having = with QueryBuilderScope.new(self) yield
      self
    end

    # SQL field(s) to be returned after an `insert` statement.
    # > `*` (wildcard) means all fields.
    def returning(fields : OneOrMoreFieldsType) : QueryBuilder
      unless query_method == :insert
        raise DBX::Error.new(
          %("returning" method SHOULD be used only with "insert" statement.)
        )
      end

      _fields = _build_selected_fields(fields)

      @returning = if @returning.nil? || @returning.not_nil!.compare("*") == 0
                     _fields
                   else
                     "#{@returning}, #{_fields}"
                   end
      self
    end

    # :ditto:
    def returning(*name : FieldType) : QueryBuilder
      self.returning(name)
    end

    # Returns the SQL field(s) to be returned after an `insert` statement.
    # > `*` (wildcard) means all fields.
    def returning : String?
      @returning
    end
  end
end
