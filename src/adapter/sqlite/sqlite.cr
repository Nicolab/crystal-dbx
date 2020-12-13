# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

# Work in Progress
puts "\u{1F47B} WARNING! SQLite adapter is not ready for prod. \
  SHOULD be used only for development."

require "sqlite3"
require "../../adapter"
require "../../query_builder"

module DBX::Adapter
  # Injects `adapter_class` method (example, it's used in the models).
  macro inject_sqlite
    alias AdapterDB = DBX::Adapter::SQLite
    protected class_getter adapter_class : DBX::Adapter::Base.class = AdapterDB
  end

  # SQLite adapter
  class SQLite < Base
    alias QueryBuilder = SQLiteQueryBuilder

    # Returns query builder class adapted for SQLite.
    def builder_class : DBX::QueryBuilder.class
      SQLite::QueryBuilder
    end

    # Returns query builder class adapted for SQLite.
    def self.builder_class : DBX::QueryBuilder.class
      SQLite::QueryBuilder
    end

    # :inherit:
    def create(
      query : DBX::QueryExecutor,
      data,
      as types,
      returning : DBX::QueryBuilder::OneOrMoreFieldsType = "*",
      pk_name : DBX::QueryBuilder::FieldType = :id,
      pk_type = Int64?
    )
      unless query.builder.query_method.nil?
        raise DBX::Error.new(
          %("create" method MUST not be composed. \
          Uses "create" only, without other statement except the table. \
          "Test.create" ou "query.table(:tests).create".))
      end

      # fixme: double quote bug (around table name)
      table_name = query.builder.table.gsub(%("), "")
      # todo: use last_insert_id() instead
      last_id = query.insert(data).exec!.last_insert_id
      # query_last_id = db.scalar(last_insert_id())

      # case pk_type
      # when Int32, Int32?   then last_id = query_last_id.as(Int32)
      # when Int64, Int64?   then last_id = query_last_id.as(Int64)
      # when UUID, UUID?     then last_id = query_last_id.as(UUID)
      # when String, String? then last_id = query_last_id.as(String)
      # else
      #   raise ArgumentError.new "Bad pk_type. MUST be Int32, Int64, UUID, String or Nil"
      # end

      raise DB::NoResultsError.new("Cannot create") if last_id.nil?

      query
        .table(table_name)
        .find(pk_name, last_id)
        .select(returning)
        .query_one!(types)
    end

    private def last_insert_id : String
      "SELECT LAST_INSERT_ROWID()"
    end
  end

  # `QueryBuilder` for SQLite.
  # :inherit:
  class SQLiteQueryBuilder < QueryBuilder
  end
end