# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "./spec_helper"

# NOTE: query_spec.cr `#find` has some tests for the table(s) argument.

describe "DBX::QueryBuilder#table" do
  builder = BUILDER

  it "supports Symbol (single table)" do
    query = builder.table(:test).find
    query.table.should eq "test"
    sql, args = query.build
    count_query
    norm(sql).should eq %(SELECT * FROM test)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0
  end

  it "supports String (single table)" do
    query = builder.table("test").find
    query.table.should eq "test"
    sql, args = query.build
    count_query
    norm(sql).should eq %(SELECT * FROM test)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0
  end

  it "supports Array of Symbol (multi tables)" do
    query = builder.table([:test1, :test2]).find
    query.table.should eq "test1, test2"
    sql, args = query.build
    count_query
    norm(sql).should eq %(SELECT * FROM test1, test2)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0
  end

  it "supports Tuple of Symbol (multi tables)" do
    query = builder.table({:test1, :test2}).find
    query.table.should eq "test1, test2"
    sql, args = query.build
    count_query
    norm(sql).should eq %(SELECT * FROM test1, test2)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0
  end

  it "supports variadic Symbol (multi tables)" do
    query = builder.table(:test1, :test2).find
    query.table.should eq "test1, test2"
    sql, args = query.build
    count_query
    norm(sql).should eq %(SELECT * FROM test1, test2)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0
  end

  it "supports variadic String (multi tables)" do
    query = builder.table("test1", "test2").find
    query.table.should eq "test1, test2"
    sql, args = query.build
    count_query
    norm(sql).should eq %(SELECT * FROM test1, test2)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0
  end

  it "supports block statement" do
    query = builder.table { "#{q("posts")} AS p, articles a" }.find
    query.table.should eq norm(%("posts" AS p, articles a))
    sql, args = query.build
    count_query
    norm(sql).should eq %(SELECT * FROM "posts" AS p, articles a)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0
  end
end
