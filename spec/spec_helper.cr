# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "spec"
require "../src/dbx"

# Normalizes string (used for SQL query).
def norm(str : String) : String
  str.gsub(/\t|\n|\s\s\s+/, " ").gsub("  ", " ").strip
end

# Opens a connection to the DB entry point *name*.
def db_open(name : String = "app", strict : Bool = false)
  DBX.open(name, ENV["DB_URI"], strict: strict)
end

# Opens a connection to the DB entry point *name*.
def db_destroy(name : String = "app")
  DBX.destroy(name)
end
