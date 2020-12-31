# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "pg"
require "../../adapter"
require "../../query_builder"

module DBX::Adapter
  # Injects `adapter_class` method (example, it's used in the models).
  macro inject_pg
    alias AdapterDB = DBX::Adapter::PostgreSQL
    protected class_getter adapter_class : DBX::Adapter::Base.class = AdapterDB
  end

  # PostgreSQL adapter
  class PostgreSQL < Base
    alias QueryBuilder = PGQueryBuilder

    # Returns query builder class adapted for PostgreSQL.
    def builder_class : DBX::QueryBuilder.class
      PostgreSQL::QueryBuilder
    end

    # Returns query builder class adapted for PostgreSQL.
    def self.builder_class : DBX::QueryBuilder.class
      PostgreSQL::QueryBuilder
    end

    # :inherit:
    # > To get recorded data, PostgreSQL adapter use `RETURNING` SQL statement.
    #   *pk_name* and *pk_type* are useless and ignored,
    #   thanks PostgreSQL `RETURNING` that makes it simpler and more efficient :)
    def create!(
      query : DBX::Query,
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

      query.insert(data).returning(returning).query_one!(types)
    end
  end

  # `QueryBuilder` for PostgreSQL.
  # :inherit:
  class PGQueryBuilder < QueryBuilder
    QUOTE = '"'

    @placeholder = "$"

    # Adds placeholder specific to PostgreSQL.
    # :inherit:
    def ph(position : Int)
      "#{@placeholder}#{position}"
    end

    private def build_query_insert : String
      sql = super
      sql = "#{sql} RETURNING #{returning}" if returning
      sql
    end

    private def build_query_update : String
      sql = super
      sql = "#{sql} RETURNING #{returning}" if returning
      sql
    end

    private def build_query_delete : String
      sql = super
      sql = "#{sql} RETURNING #{returning}" if returning
      sql
    end
  end
end
