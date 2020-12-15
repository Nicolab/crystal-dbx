# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "../../spec_helper"
require "../../../src/query_builder/executor"

describe "DBX::QueryExecutor" do
  before_each do
    db_open
    create_table_test
    insert_table_test
  end

  after_each do
    drop_table_test
    DBX.destroy
    DBX.dbs.size.should eq 0
  end

  it "insert" do
    data = {name: "test_insert", about: "Crystal is awesome!", age: 10}
    query = new_query_executor

    query.insert(:tests, data).exec!.rows_affected.should eq 1

    query
      .find(:tests)
      .select(:name, :about, :age)
      .where(:name, "test_insert")
      .query_one(as: {name: String, about: String, age: Int32})
      .should eq data
  end

  it "create" do
    test = new_query_executor.table(:tests).create(
      {name: "created", about: "about", age: 1},
      as: {String, Int32},
      returning: {:name, :age},
      pk_name: :id,
      pk_type: Int64
    )

    test.should be_a({String, Int32})
    test.should eq({"created", 1})
    new_query_executor.find(:tests).select(:id).where(:name, "created")
      .scalar!.as(Int64).should be >= 2

    test = new_query_executor.table(:tests).create(
      {name: "created2", about: "about", age: 1},
      as: {name: String, age: Int32},
      returning: {:name, :age}
    )

    test.should be_a({name: String, age: Int32})
    test.should eq({name: "created2", age: 1})
    new_query_executor.find(:tests).select(:id).where(:name, "created2")
      .scalar!.as(Int64).should be >= 3
  end

  it "find, select, where" do
    new_query_executor
      .find(:tests)
      .select(:id)
      .where(:name, "Nico")
      .scalar!
      .as(Int64)
      .should be >= 1
  end

  it "update, where" do
    new_query_executor
      .update(:tests, {name: "updated!"})
      .where(:name, "Nico")
      .exec!
      .rows_affected.should eq 1

    id = new_query_executor
      .find(:tests)
      .select(:id)
      .where(:name, "updated!")
      .scalar!
      .as(Int64)

    id.should_not be_nil

    expect_raises(DB::NoResultsError) {
      new_query_executor
        .table(:tests)
        .update(:id, 0, {name: "updated2!"})
        .exec!
    }

    new_query_executor
      .table(:tests)
      .update(:id, id, {"name" => "updated2!"})
      .exec!
      .rows_affected.should eq 1

    new_query_executor
      .find(:tests)
      .select(:id)
      .where(:name, "updated2!")
      .scalar!
      .as(Int64)
      .should_not be_nil
  end

  it "delete, where" do
    id = new_query_executor
      .find(:tests)
      .select(:id)
      .where(:name, "Nico")
      .limit(1)
      .scalar!
      .as(Int64)

    id.should_not be_nil

    new_query_executor
      .find(:tests)
      .count(:id)
      .where(:name, "Nico")
      .scalar!
      .as(Int64)
      .should eq 1

    new_query_executor
      .delete(:tests)
      .where(:name, "Nico")
      .exec!
      .rows_affected.should eq 1

    new_query_executor
      .find(:tests)
      .count(:id)
      .where(:name, "Nico")
      .scalar!
      .as(Int64)
      .should eq 0

    expect_raises(DB::NoResultsError) {
      new_query_executor
        .table(:tests)
        .delete(:id, id)
        .exec!
    }

    insert_table_test

    id = new_query_executor
      .find(:tests)
      .select(:id)
      .where(:name, "Nico")
      .limit(1)
      .scalar!
      .as(Int64)

    id.should_not be_nil

    new_query_executor
      .table(:tests)
      .delete(:id, id)
      .exec!
      .rows_affected.should eq 1
  end

  it "drop" do
    if ADAPTER_NAME == :pg
      expected_error_no_table = /does not exist/
    else
      expected_error_no_table = /no such table/
    end

    new_query_executor.drop(:tests, false).exec!.should be_a DB::ExecResult

    expect_raises(Exception, expected_error_no_table) {
      new_query_executor.drop(:tests, false).exec
    }

    new_query_executor.drop(:tests, true).exec.should be_a DB::ExecResult
    new_query_executor.drop(:tests, true).exec!.should be_a DB::ExecResult
  end

  it "alter" do
    if ADAPTER_NAME == :pg
      expected_error_no_table = /does not exist/
    else
      expected_error_no_table = /no such column/
    end

    expect_raises(Exception, expected_error_no_table) {
      new_query_executor.update(:tests, {test_column: "yeah!"}).exec
    }

    new_query_executor.table(:tests).alter("add", "test_column", "varchar(255)").exec!
    new_query_executor.update(:tests, {test_column: "yeah!"}).exec
  end
end
