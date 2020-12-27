# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX
  class QueryBuilder
    # Finalizes the current query.
    private def end_query(sql : String) : SQLandArgsType
      sql = sql.strip
      args = @args
      query_method = @query_method
      reset_query
      @last_query_method = query_method
      @last_query = sql
      @query_count += 1
      {sql, args}
    end

    # Converts `NamedTuple` to `DataHashType`.
    def to_data_h(data : Hash | NamedTuple) : DataHashType
      h = DataHashType.new
      data.each { |k, v| h[k] = v }
      h
    end

    # Builds the current query and returns SQL (string) and arguments (array).
    #
    # ```
    # sql, args = builder.build
    # ```
    def build : SQLandArgsType
      {% begin %}
        case @query_method
        {% for method in [
                           :find,
                           :insert,
                           :update,
                           :delete,
                           :drop,
                           :alter,
                           :query,

                           # Maintenance
                           :analyze,
                           :check,
                           :checksum,
                           :optimize,
                           :repair,
                         ] %}
          when :{{method.id}} then end_query(build_query_{{method.id}})
        {% end %}
          when :update_one then end_query(build_query_update)
          when :delete_one then end_query(build_query_delete)
        else
          raise Error.new "Bad QueryBuilder method. #{@query_method}"
        end
      {% end %}
    end

    def find : QueryBuilder
      @query_method = :find
      self
    end

    def find(table_name : OneOrMoreFieldsType) : QueryBuilder
      find
      table(table_name)
    end

    # Adds `find` to current query
    # and defines in raw form the SQL statement of the table(s).
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
    def find(&block) : QueryBuilder
      find
      @table = "#{with QueryBuilderScope.new(self) yield}"
      self
    end

    # Finds one resource by its primary key.
    #
    # Same as:
    #
    # ```
    # builder.find.where(pk_name, pk_value)
    # ```
    def find(pk_name, pk_value) : QueryBuilder
      find.where(pk_name, pk_value)
    end

    private def build_query_find : String
      @select = "*" if @select.empty?

      sql = "SELECT #{@select} FROM #{@table}"
      sql = "#{sql} #{@join}" if !@join.empty?
      sql = "#{sql} WHERE #{@where}" if !@where.empty?
      sql = "#{sql} GROUP BY #{@group_by}" if !@group_by.empty?
      sql = "#{sql} HAVING #{@having}" if !@having.empty?
      sql = "#{sql} ORDER BY #{@order_by}" if !@order_by.empty?
      sql = "#{sql} LIMIT #{@limit}" if !@limit.to_s.empty?
      sql = "#{sql} OFFSET #{@offset}" if !@offset.to_s.empty?
      sql
    end

    def insert(data : Hash | NamedTuple) : QueryBuilder
      @query_method = :insert
      @data = to_data_h(data)
      self
    end

    def insert(table : OneOrMoreFieldsType, data : Hash | NamedTuple) : QueryBuilder
      insert(data)
      table(table)
    end

    private def build_query_insert : String
      raise Error.new "No data to insert" unless data = @data

      "INSERT INTO #{@table} (#{data.map { |field, _| quote(field) }.join(", ")})" \
      " VALUES (#{add_args_and_fields_from_data(data)})"
    end

    def update(data : Hash | NamedTuple) : QueryBuilder
      @query_method = :update
      raise Error.new "No data to update" unless data
      @data_kv = add_args_and_kv_from_data(to_data_h(data))
      self
    end

    def update(table : OneOrMoreFieldsType, data : Hash | NamedTuple) : QueryBuilder
      update(data)
      table(table)
    end

    def update(pk_name, pk_value, data : Hash | NamedTuple) : QueryBuilder
      update(data)
      @query_method = :update_one
      self.where(pk_name, pk_value)
    end

    private def build_query_update : String
      raise Error.new "No data to update" unless @data_kv

      sql = "UPDATE #{@table} SET #{@data_kv}"
      sql = "#{sql} WHERE #{@where}" if !@where.empty?
      sql = "#{sql} ORDER BY #{@order_by}" if !@order_by.empty?
      sql = "#{sql} LIMIT #{@limit}" if !@limit.to_s.empty?
      sql
    end

    def delete : QueryBuilder
      @query_method = :delete
      self
    end

    def delete(table : OneOrMoreFieldsType) : QueryBuilder
      delete
      table(table)
    end

    def delete(pk_name, pk_value) : QueryBuilder
      delete
      @query_method = :delete_one
      self.where(pk_name, pk_value)
    end

    private def build_query_delete : String
      sql = "DELETE FROM #{@table}"
      sql = "#{sql} WHERE #{@where}" if !@where.empty?
      sql = "#{sql} ORDER BY #{@order_by}" if !@order_by.empty?
      sql = "TRUNCATE TABLE #{@table}" if @returning.nil? && sql == "DELETE FROM #{@table}"
      sql
    end

    def drop(check_exists = true) : QueryBuilder
      @query_method = :drop
      @options = check_exists
      self
    end

    def drop(table : OneOrMoreFieldsType, check_exists = true) : QueryBuilder
      drop(check_exists)
      table(table)
    end

    private def build_query_drop : String
      raise Error.new "Option undefined." if @options.nil?
      # check_exists : Bool
      "DROP TABLE#{@options ? " IF EXISTS" : ""} #{@table}"
    end

    def alter(command : String, field : String, data_type = "") : QueryBuilder
      @query_method = :alter
      @options = {command: command, field: field, data_type: data_type}
      self
    end

    def alter(
      table : OneOrMoreFieldsType,
      command : String,
      field : String,
      data_type = ""
    ) : QueryBuilder
      alter(command, field, data_type)
      table(table)
    end

    private def build_query_alter : String
      options = @options.as(NamedTuple(
        command: String,
        field: String,
        data_type: String))

      if !options.has_key?(:command) ||
         !options.has_key?(:field) ||
         !options.has_key?(:data_type)
        raise Error.new "Options undefined."
      end

      sql = "ALTER TABLE #{@table}"
      sql = "#{sql} #{options[:command].gsub('_', ' ').upcase} #{options[:field]}"
      sql = "#{sql} #{options[:data_type]}" if !options[:data_type].empty?
      sql
    end

    {% for method in %w(analyze check checksum optimize repair) %}
      # Builds the `{{method.upcase.id}}` query
      def {{method.id}} : QueryBuilder
        @query_method = :{{method.id}}
        self
      end

      # :ditto:
      def {{method.id}}(table : OneOrMoreFieldsType) : QueryBuilder
        {{method.id}}
        table(table)
      end

      private def build_query_{{method.id}} : String
        "{{method.upcase.id}} TABLE #{@table}"
      end
    {% end %}

    # Generates a raw query.
    # > Be careful, you have to manage arguments and quotes.
    #
    # Example:
    #
    # ```
    # puts builder.query { "
    #   SELECT * FROM #{q(tests)}
    #   status = #{arg(true)}
    #   AND (
    #     #{q(:date)} <= #{arg(Time.utc - 1.day)}
    #     OR role = #{arg(:admin)}
    #   )
    #   LIMIT 1
    # " }
    # ```
    #
    # Generates:
    #
    # ```text
    # SELECT *
    # FROM "tests"
    # WHERE status = $1
    # AND ("date" <= $2 OR role = $3)
    # LIMIT 1
    # ```
    def query(&block) : QueryBuilder
      @query_method = :query
      @query = " #{with QueryBuilderScope.new(self) yield} "
      self
    end

    private def build_query_query : String
      @query
    end

    # Returns the last query.
    def last_query : String
      @last_query
    end

    # Returns the last query method.
    def last_query_method : Symbol?
      @last_query_method
    end

    # Returns the query method.
    def query_method : Symbol?
      @query_method
    end

    # Returns number of queries made by the current instance.
    def query_count : Int
      @query_count
    end
  end
end

# ---------------------------------------------------------------------------- #
# NOTE: String performance
# require "benchmark"

# VAR1 = "Variable 1"
# VAR2 = "Variable 2"

# Benchmark.ips do |x|
#   x.report("=#") do
#     sql = "1"
#     sql = "#{sql}this a #{VAR1} test 1 #{VAR2}"
#     sql = "#{sql}this a #{VAR1} test 2 #{VAR2}"
#     sql = "#{sql}this a #{VAR1} test 3 #{VAR2}"
#     sql
#   end

#   x.report("+=") do
#     sql = "1"
#     sql += "this a #{VAR1} test 1 #{VAR2}"
#     sql += "this a #{VAR1} test 2 #{VAR2}"
#     sql += "this a #{VAR1} test 3 #{VAR2}"
#     sql
#   end
# end

# concat   2.68M (372.51ns) (± 2.40%)   224B/op   1.67× slower
# interpo   4.49M (222.80ns) (± 2.32%)  64.0B/op        fastest
# build   2.68M (373.83ns) (± 2.70%)   176B/op   1.68× slower
# ---------------------------------------------------------------------------- #
