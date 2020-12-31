# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "../query_builder"

# DB adapter(s) used by `DBX::QueryBuilder` and `DBX::ORM`.
module DBX::Adapter
  # Base adapter.
  abstract class Base
    @db : DB::Database

    def initialize(@db : DB::Database)
    end

    def db
      @db
    end

    # Returns a new query builder instance.
    def new_builder : QueryBuilder
      self.builder_class.new
    end

    # Returns a new query builder instance.
    def self.new_builder : QueryBuilder
      self.builder_class.new
    end

    # Returns query builder class.
    def self.builder_class : QueryBuilder.class
      raise NotImplementedError.new(
        "'#{self}' model MUST define '#{self}.builder_class' method."
      )
    end

    # Creates a new record and returns.
    # See `DBX::Query#create` for more details.
    abstract def create(
      query : DBX::Query,
      data : Hash | NamedTuple,
      as types,
      returning : DBX::QueryBuilder::OneOrMoreFieldsType = "*",
      pk_name : DBX::QueryBuilder::FieldType = :id,
      pk_type = Int64?
    )
  end
end
