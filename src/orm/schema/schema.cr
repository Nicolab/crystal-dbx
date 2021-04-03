# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "./inject_fields"
require "./def"
require "./inject_for_final"

module DBX::ORM
  # `Model` Schema.
  class Schema
    alias RelationDef = {name: String, model_class: DBX::ORM::Model.class, has_many: Bool, has_one: Bool}
    alias MetaField = {name: String, rel_name: String, sql: String, rel_sql: String}
    alias MetaFieldHash = Hash(String, MetaField)

    FIELDS    = {} of String => HashLiteral(String, ASTNode)
    RELATIONS = {} of String => ASTNode

    include DB::Serializable
    include JSON::Serializable
    include JSON::Serializable::Unmapped
    include DBX::ORM::SchemaInjectForFinal
    include DBX::ORM::SchemaInjectFields

    # Always returns this record's primary key value, even when the primary key
    # isn't named `_pk`.
    @[DB::Field(ignore: true)]
    @[JSON::Field(ignore: true)]
    def _pk!
      self._pk.not_nil!
    end

    # Same as `_pk` but may return `nil` when the record hasn't been saved
    # instead of raising.
    @[DB::Field(ignore: true)]
    @[JSON::Field(ignore: true)]
    def _pk
      self.id
    end

    # Unique (virtual) key used to compare the uniqueness of models.
    # By default this method returns the primary key (`_pk`) value.
    #
    # This method avoid to rely directly on the primary key in case there is none in
    # the structure of the SQL table (even if there should always be one).
    # Used in the relation algorithm.
    # Also, can be useful when there is a need to check the uniqueness in other cases.
    #
    # If for some reason your model does not have a primary key,
    # you can override this method to return a unique result
    # related to the fields in your table, for example:
    #
    # ```
    # @[DB::Field(ignore: true)]
    # @[JSON::Field(ignore: true)]
    # def _ukey
    #   "#{self.group_id}.#{self.user_id}"
    # end
    # ```
    @[DB::Field(ignore: true)]
    @[JSON::Field(ignore: true)]
    def _ukey
      self._pk
    end

    orm_schema_inject_fields

    macro inherited
      @@relations_def : Hash(String, RelationDef) = Hash(String, RelationDef).new

      macro finished
        orm_schema_inject_for_final
      end
    end
  end
end
