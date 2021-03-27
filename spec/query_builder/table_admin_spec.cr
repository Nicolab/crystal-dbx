# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "./spec_helper"

describe "DBX::QueryBuilder table admin" do
  builder = BUILDER

  it "drop table IF EXISTS" do
    query = builder.table("test").drop
    query.table.should eq "test"
    sql, args = query.build
    count_query
    sql.should be_a(String)
    norm(sql).should eq %(DROP TABLE IF EXISTS test)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0

    # Multi tables
    query = builder.table(["foo", "bar", "baz"]).drop
    count_query
    query.table.should eq "foo, bar, baz"
    sql, args = query.build
    sql.should be_a(String)
    norm(sql).should eq %(DROP TABLE IF EXISTS foo, bar, baz)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0
  end

  it "drop table - Don't check table(s) exists" do
    query = builder.table("test").drop(false)
    query.table.should eq "test"
    sql, args = query.build
    count_query
    sql.should be_a(String)
    norm(sql).should eq %(DROP TABLE test)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0

    # Multi tables
    query = builder.table(["foo", "bar", "baz"]).drop(false)
    count_query
    query.table.should eq "foo, bar, baz"
    sql, args = query.build
    sql.should be_a(String)
    norm(sql).should eq %(DROP TABLE foo, bar, baz)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0
  end

  it "alter table" do
    query = builder.table("test").alter("add", "test_column", "varchar(255)")
    query.table.should eq "test"
    sql, args = query.build
    count_query
    sql.should be_a(String)
    norm(sql).should eq %(ALTER TABLE test ADD test_column varchar(255))
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0

    sql, _ = builder.table("test").alter("modify_column", "test_column", "int NOT NULL").build
    count_query
    norm(sql).should eq %(ALTER TABLE test MODIFY COLUMN test_column int NOT NULL)

    sql, _ = builder.table("test").alter("modify", "test_date", "datetime NOT NULL").build
    count_query
    norm(sql).should eq %(ALTER TABLE test MODIFY test_date datetime NOT NULL)

    sql, _ = builder.table("test").alter("drop_column", "test_column").build
    count_query
    norm(sql).should eq %(ALTER TABLE test DROP COLUMN test_column)

    sql, _ = builder.table("test").alter("drop_index", "index_name").build
    count_query
    norm(sql).should eq %(ALTER TABLE test DROP INDEX index_name)

    sql, _ = builder.table("test").alter(
      "add_constraint",
      "my_primary_key",
      "PRIMARY KEY (column1, column2)"
    ).build

    count_query

    norm(sql).should eq(
      %(ALTER TABLE test ADD CONSTRAINT my_primary_key PRIMARY KEY (column1, column2))
    )
  end
end
