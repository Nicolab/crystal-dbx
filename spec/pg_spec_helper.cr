# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "pg"

def create_table_test
  db = DBX.open("app")
  db.exec "create table tests (name varchar(255), city varchar(50), age int4)"
end

def drop_table_test
  db = DBX.open("app")
  db.exec "drop table if exists tests"
end

def insert_table_test(name : String = "Nico", city : String = "Biarritz", age : Int32 = "38")
  db = DBX.open("app")
  db.exec(
    "insert into tests values ($1, $2, $3) RETURNING id",
    name, city, age
  )
end
