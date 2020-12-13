# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

{% begin %}
{% if env("DB_TYPE") == "sqlite" %}
  require "../spec_helper"

  def create_table_test(db_entry = "app")
    db = DBX.db(db_entry)
    db.exec "create table tests (id INTEGER PRIMARY KEY, name varchar(255), about varchar(50), age int4)"
  end

  def drop_table_test(db_entry = "app")
    db = DBX.db(db_entry)
    er = db.exec "DROP TABLE IF EXISTS tests"
  end

  def insert_table_test(name : String = "Nico", about : String = "Lives in Biarritz", age : Int32 = 38)
    db = DBX.db("app")
    db.exec(
      "insert into tests (name, about, age) values (?, ?, ?)",
      name, about, age
    )
  end

  def insert_table_test(*, db_entry = "app", name : String = "Nico", about : String = "Lives in Biarritz", age : Int32 = 38)
    db = DBX.db(db_entry)
    db.exec(
      "insert into tests (name, about, age) values (?, ?, ?)",
      name, about, age
    )
  end

  def select_table_test(db_entry = "app")
    db = DBX.db(db_entry)
    res = db.query(
      "SELECT * FROM tests"
    )
    res.close
  end

  # Load PG adapter
  require "../../src/adapter/sqlite"
  alias DBAdapter = DBX::Adapter::SQLite
  ADAPTER_NAME = :sqlite

  def new_query_executor
    DBX::QueryExecutor.new(DBAdapter.new(db_open))
  end

  # Include all common DB (adapter) tests
  require "../adapter_tests/**"
{% end %}
{% end %}