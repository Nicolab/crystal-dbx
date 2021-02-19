# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

{% begin %}
{% if env("DB_TYPE") == "pg" %}
  puts "\u{1F9E9} PostgreSQL adapter"
  require "../spec_helper"

  def create_table_test(connection = "app")
    db = DBX.db(connection)
    db.exec "create table tests (id BIGSERIAL PRIMARY KEY, name varchar(255), about varchar(50), age int4)"
  end

  def create_table_test_with_custom_pk(connection = "app")
    db = DBX.db(connection)
    db.exec "create table tests (uid varchar(255) PRIMARY KEY, name varchar(255), about varchar(50), age int4)"
  end

  def drop_table_test(connection = "app")
    db = DBX.db(connection)
    db.exec "drop table if exists tests"
  end

  def insert_table_test(name : String = "Nico", about : String = "Lives in Biarritz", age : Int32 = 38)
    db = DBX.db("app")
    db.exec(
      "insert into tests (name, about, age) values ($1, $2, $3)  RETURNING *",
      name, about, age
    )
  end

  def insert_table_test_with_custom_pk(
    uid : String, name : String = "Nico", about : String = "Lives in Biarritz", age : Int32 = 38
  )
    db = DBX.db("app")
    db.exec(
      "insert into tests (uid, name, about, age) values ($1, $2, $3, $4)  RETURNING *",
      uid, name, about, age
    )
  end

  def insert_table_test(*, connection = "app", name : String = "Nico", about : String = "Lives in Biarritz", age : Int32 = 38)
    db = DBX.db(connection)
    db.exec(
      "insert into tests (name, about, age) values ($1, $2, $3)  RETURNING *",
      name, about, age
    )
  end

  def select_table_test(connection = "app")
    db = DBX.db(connection)
    res = db.query(
      "SELECT * FROM tests"
    )
    res.close
  end

  # Load adapter
  require "../../src/adapter/pg"
  alias DBAdapter = DBX::Adapter::PostgreSQL
  ADAPTER_NAME = :pg

  def new_query
    DBX::Query.new(DBAdapter.new(db_open))
  end

  # Include all common DB (adapter) tests
  require "../adapter_tests/**"
{% end %}
{% end %}
