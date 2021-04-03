# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX::ORM::SchemaInjectFields
  macro orm_schema_inject_fields
    @@fields : MetaFieldHash = MetaFieldHash.new
    @@sql_fields : String = ""
    @@sql_rel_fields : String = ""

    # Returns all SQL fields definitions.
    def self.fields : MetaFieldHash
      @@fields
    end

    # Returns the SQL fields of the model separated by a comma (table.column, ...).
    def self.sql_fields : String
      @@sql_fields
    end

    # Returns the SQL fields of the model (for the relations) separated by a comma (table.column, ...).
    def self.sql_rel_fields : String
      @@sql_rel_fields
    end
  end
end
