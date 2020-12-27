# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX
  # Query executor.
  # See also: https://crystal-lang.github.io/crystal-db/api/latest/DB/QueryMethods.html
  class QueryExecutor
    @builder : DBX::QueryBuilder
    @db : DB::Database
    @tx : DB::Transaction?

    def initialize(@adapter : DBX::Adapter::Base)
      @builder = @adapter.new_builder
      @db = @adapter.db
    end

    # Executes current built query that is expected to return an `DB::ExecResult`.
    def exec!
      query_method = @builder.query_method
      sql, args = @builder.build
      er = @db.exec(sql, args: args)

      if (
           query_method == :insert ||
           query_method == :update_one ||
           query_method == :update ||
           query_method == :delete_one ||
           query_method == :delete
         ) && er.rows_affected == 0
        raise DB::NoResultsError.new "DB::ExecResult: No rows affected"
      end

      er
    end

    # :ditto:
    # Returns `nil` instead of raising `DB::NoResultsError`.
    def exec
      exec!
    rescue DB::NoResultsError
      nil
    end

    # Executes current built query that is expected to return one or more results.
    #
    # ```
    # tests = [] of Array(String | Int32)
    # rs = query.find(:tests).select(:name, :age).query
    #
    # begin
    #   while rs.move_next
    #     name = rs.read(String)
    #     age = rs.read(Int32)
    #     tests << [name, age]
    #   end
    # ensure
    #   rs.close
    # end
    # ```
    def query
      sql, args = @builder.build
      @db.query(sql, args: args)
    end

    # Executes current built query and yields a `DB::ResultSet` with the results.
    # The `DB::ResultSet` is closed automatically.
    #
    # ```
    # tests = [] of Array(String | Int32)
    # query.find(:tests).select(:name, :age).query do |rs|
    #   rs.each do
    #     name = rs.read(String)
    #     age = rs.read(Int32)
    #     tests << [name, age]
    #   end
    # end
    # ```
    def query(&block)
      sql, args = @builder.build
      @db.query(sql, args: args) { |rs| yield rs }
    end

    # Executes current built query that is expected to return one result.
    def query_all(as types)
      sql, args = @builder.build
      @db.query_all(sql, args: args, as: types)
    end

    # Executes current built query and yields a `DB::ResultSet` positioned
    # at the beginning of each row, returning an `Array` of the values of the blocks.
    def query_all(&block)
      sql, args = @builder.build
      @db.query_all(sql, args: args) { |rs| yield rs }
    end

    # Executes current built query and yields the `DB::ResultSet` once per each row.
    def query_each(&block)
      sql, args = @builder.build
      @db.query_each(sql, args: args) { |rs| yield rs }
    end

    # Executes current built query that is expected to return one result.
    def query_one!(as types)
      sql, args = @builder.build
      @db.query_one(sql, args: args, as: types)
    end

    # :ditto:
    # If no result found, this method returns `nil` instead of raising `DB::NoResultsError`.
    def query_one(as types)
      query_one!(types)
    rescue DB::NoResultsError
      nil
    end

    # Executes current built query that expects at most a single row and yields
    # a `DB::ResultSet` positioned at that first row.
    def query_one!(&block)
      sql, args = @builder.build
      @db.query_one(sql, args: args) { |rs| yield rs }
    end

    # :ditto:
    # If no result found, this method returns `nil` instead of raising `DB::NoResultsError`.
    def query_one(&block)
      query_one! { |rs| yield rs }
    rescue DB::NoResultsError
      nil
    end

    # Executes current built query and returns a single scalar value.
    def scalar!
      sql, args = @builder.build
      @db.scalar(sql, args: args)
    end

    # :ditto:
    # If no result found, this method returns `nil` instead of raising `DB::NoResultsError`.
    # So the type MUST be nillable:
    #
    # ```
    # query
    #   .find(:tests)
    #   .select(:name)
    #   .where(:name, "Terminator")
    #   .scalar
    #   .as(String?)
    # # => String | Nil
    # ```
    def scalar
      scalar!
    rescue DB::NoResultsError
      nil
    end

    # See `DBX::QueryBuilder#query`
    def raw_query(&block) : QueryExecutor
      @builder.query {
        with QueryBuilderScope.new(@builder) yield
      }
      self
    end

    # Builds current query and returns `sql, args`.
    # See `DBX::QueryBuilder#build` method.
    def build : Tuple
      @builder.build
    end

    # Returns `DBX::QueryBuilder` instance used in current `QueryExecutor` instance.
    def builder : DBX::QueryBuilder
      @builder
    end

    # --------------------------------------------------------------------------

    # Creates a new record and returns.
    #
    # ```
    # query.table(:tests).create!(
    #   {name: "Baby", about: "I'm a baby", age: 1},
    #   as: {String, Int32},
    #   returning: {:name, :age}
    # )
    # # => {"Baby", 1}
    #
    # query.table(:tests).create!(
    #   {name: "Baby", about: "I'm a baby", age: 1},
    #   as: {name: String, age: Int32},
    #   returning: {:name, :age}
    # )
    # # => {name: "Baby", age: 1}
    # ```
    def create!(
      data : Hash | NamedTuple,
      as types,
      returning : DBX::QueryBuilder::OneOrMoreFieldsType = "*",
      pk_name : DBX::QueryBuilder::FieldType = :id,
      pk_type = Int64?
    )
      @adapter.create!(self, data, types, returning, pk_name, pk_type)
    end

    # Shortcut, same as `query_one!(types)`.
    def to_o!(as types)
      query_one!(types)
    end

    # Shortcut, same as `query_one(types)`.
    def to_o(as types)
      query_one(types)
    end

    # Shortcut, same as `query_one!(&block)`.
    def to_o!(&block)
      query_one! { |rs| yield rs }
    end

    # Shortcut, same as `query_one(&block)`.
    def to_o(&block)
      query_one { |rs| yield rs }
    end

    # Shortcut, same as `query_all(types)`.
    def to_a(as types)
      query_all(types)
    end

    # Shortcut, same as `query_all(&block)`.
    def to_a(&block)
      query_all { |rs| yield rs }
    end

    macro method_missing(call)
      {% begin %}
        # See `DBX::QueryBuilder#{{call.name}}` method.
        def {{call.name.id}}({{call.args.splat}}) : DBX::QueryExecutor
          @builder.{{call.name.id}}({{call.args.splat}})
          self
        end
      {% end %}
    end
  end
end
