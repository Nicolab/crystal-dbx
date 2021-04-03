# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "mg"

module Migrations
  class CreateRelationsTables < MG::Base
    def up : String
      <<-SQL
        CREATE TABLE IF NOT EXISTS #{User.table_name} (
          id BIGINT PRIMARY KEY,
          username VARCHAR (50) UNIQUE NOT NULL,
          profile_id BIGINT
        );

        CREATE TABLE IF NOT EXISTS #{Profile.table_name} (
          id BIGINT PRIMARY KEY,
          name VARCHAR(120) NOT NULL
        );

        CREATE TABLE IF NOT EXISTS #{Tag.table_name} (
          id BIGINT PRIMARY KEY,
          name VARCHAR(50) NOT NULL,
          profile_id BIGINT,
          user_id BIGINT
        );
      SQL
    end

    def down : String
      <<-SQL
        DROP TABLE IF EXISTS
          #{Tag.table_name},
          #{Profile.table_name},
          #{User.table_name}
        ;
      SQL
    end
  end
end
