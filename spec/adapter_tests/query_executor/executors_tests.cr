# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "../../spec_helper"
require "../../../src/query_builder/executor"

describe "DBX::QueryExecutor executors" do
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

  it "exec!" do
    test = Test.find.to_o!

    er = Test.update(
      test.id,
      {name: "test_exec!", about: "DBX query executor", age: 10}
    ).exec!

    er.rows_affected.should eq 1
    test2 = Test.find(test.id).to_o!
    test.name.should_not eq test2.name

    expect_raises(DB::NoResultsError) {
      Test.update(0, {name: "test_exec!"}).exec!
    }
  end

  it "exec" do
    Test.insert({name: "test_exec!", about: "DBX query executor", age: 10}).exec!
      .rows_affected.should eq 1

    Test.update(0, {name: "test_exec"}).exec.should be_nil
  end

  it "query" do
    tests = [] of Array(String | Int32)
    rs = new_query_executor.find(:tests).select(:name, :age).query
    begin
      while rs.move_next
        name = rs.read(String)
        age = rs.read(Int32)
        tests << [name, age]
      end
    ensure
      rs.close
    end

    tests.size.should eq 1
    tests.should eq [["Nico", 38]]

    insert_table_test(name: "DBX", age: 1)

    tests = [] of Array(String | Int32)
    rs = new_query_executor.find(:tests).select(:name, :age).query
    begin
      while rs.move_next
        name = rs.read(String)
        age = rs.read(Int32)
        tests << [name, age]
      end
    ensure
      rs.close
    end

    tests.size.should eq 2
    tests.should eq [["Nico", 38], ["DBX", 1]]

    tests = [] of Array(String | Int32)
    rs = new_query_executor.find(:tests).select(:name, :age).where(:id, 0).query
    begin
      while rs.move_next
        name = rs.read(String)
        age = rs.read(Int32)
        tests << [name, age]
      end
    ensure
      rs.close
    end

    tests.size.should eq 0
  end

  it "query(&block)" do
    tests = [] of Array(String | Int32)
    new_query_executor.find(:tests).select(:name, :age).query do |rs|
      rs.each do
        name = rs.read(String)
        age = rs.read(Int32)
        tests << [name, age]
      end
    end

    tests.size.should eq 1
    tests.should eq [["Nico", 38]]

    insert_table_test(name: "DBX", age: 1)

    tests = [] of Array(String | Int32)
    new_query_executor.find(:tests).select(:name, :age).query do |rs|
      rs.each do
        name = rs.read(String)
        age = rs.read(Int32)
        tests << [name, age]
      end
    end

    tests.size.should eq 2
    tests.should eq [["Nico", 38], ["DBX", 1]]

    tests = [] of Array(String | Int32)
    new_query_executor.find(:tests).select(:name, :age).where(:id, 0).query do |rs|
      rs.each do
        name = rs.read(String)
        age = rs.read(Int32)
        tests << [name, age]
      end
    end

    tests.size.should eq 0
  end

  it "query_all(as types)" do
    new_query_executor.find(:tests).select(:name, :age)
      .query_all({name: String, age: Int32})
      .should eq([{name: "Nico", age: 38}])

    insert_table_test(name: "DBX", age: 1)

    new_query_executor.find(:tests).select(:name, :age)
      .query_all({name: String, age: Int32})
      .should eq([{name: "Nico", age: 38}, {name: "DBX", age: 1}])

    tests = new_query_executor.find(:tests).select(:name, :age).where(:id, 0)
      .query_all({name: String, age: Int32})
    tests.should be_a Array({name: String, age: Int32})
    tests.size.should eq 0
  end

  it "query_all(&block)" do
    new_query_executor.find(:tests).select(:name)
      .query_all(&.read(String))
      .should eq(["Nico"])

    insert_table_test(name: "DBX", age: 1)

    new_query_executor.find(:tests).select(:name)
      .query_all(&.read(String))
      .should eq(["Nico", "DBX"])

    new_query_executor.find(:tests).select(:name, :age)
      .query_all { |rs|
        [rs.read(String), rs.read(Int32)]
      }
      .should eq([["Nico", 38], ["DBX", 1]])

    new_query_executor.find(:tests).select(:name, :age)
      .query_all { |rs|
        {name: rs.read(String), age: rs.read(Int32)}
      }
      .should eq([{name: "Nico", age: 38}, {name: "DBX", age: 1}])

    tests = new_query_executor.find(:tests).select(:name).where(:id, 0)
      .query_all(&.read(String))
    tests.should be_a Array(String)
    tests.size.should eq 0
  end

  it "query_each(&block)" do
    tests = [] of Array(String | Int32)
    new_query_executor.find(:tests).select(:name, :age).query_each do |rs|
      name = rs.read(String)
      age = rs.read(Int32)
      tests << [name, age]
    end

    tests.size.should eq 1
    tests.should eq [["Nico", 38]]

    insert_table_test(name: "DBX", age: 1)

    tests = [] of Array(String | Int32)
    new_query_executor.find(:tests).select(:name, :age).query_each do |rs|
      name = rs.read(String)
      age = rs.read(Int32)
      tests << [name, age]
    end

    tests.size.should eq 2
    tests.should eq [["Nico", 38], ["DBX", 1]]

    # reset
    drop_table_test
    create_table_test
    tests = [] of Array(String | Int32)
    new_query_executor.find(:tests).select(:name, :age).query_each do |rs|
      name = rs.read(String)
      age = rs.read(Int32)
      tests << [name, age]
    end

    tests.size.should eq 0
  end

  it "query_one!(as types)" do
    insert_table_test
    expect_raises(DB::Error, "more than one row") {
      new_query_executor.find(:tests).select(:name, :age)
        .query_one!({name: String, age: Int32})
    }

    expect_raises(DB::NoResultsError) {
      new_query_executor.find(:tests).select(:name, :age).where(:id, 0)
        .query_one!({name: String, age: Int32})
    }

    new_query_executor.find(:tests).select(:name, :age).limit(1)
      .query_one!({name: String, age: Int32})
      .should eq({name: "Nico", age: 38})
  end

  it "query_one(as types)" do
    insert_table_test
    expect_raises(DB::Error, "more than one row") {
      new_query_executor.find(:tests).select(:name, :age)
        .query_one({name: String, age: Int32})
    }

    new_query_executor.find(:tests).select(:name, :age).where(:id, 0)
      .query_one({name: String, age: Int32})
      .should be_nil

    new_query_executor.find(:tests).select(:name, :age).limit(1)
      .query_one({name: String, age: Int32})
      .should eq({name: "Nico", age: 38})
  end

  it "query_one!(&block)" do
    new_query_executor
      .find(:tests)
      .select(:name)
      .where(:name, "Nico")
      .query_one!(&.read(String))
      .should eq("Nico")

    expect_raises(DB::NoResultsError) {
      new_query_executor
        .find(:tests)
        .select(:name)
        .where(:name, "Terminator")
        .query_one!(&.read(String))
    }

    insert_table_test
    expect_raises(DB::Error, "more than one row") {
      new_query_executor
        .find(:tests)
        .select(:name)
        .where(:name, "Nico")
        .query_one!(&.read(String))
    }
  end

  it "query_one(&block)" do
    new_query_executor
      .find(:tests)
      .select(:name)
      .where(:name, "Nico")
      .query_one(&.read(String))
      .should eq("Nico")

    new_query_executor
      .find(:tests)
      .select(:name)
      .where(:name, "Terminator")
      .query_one(&.read(String))
      .should be_nil

    insert_table_test
    expect_raises(DB::Error, "more than one row") {
      new_query_executor
        .find(:tests)
        .select(:name)
        .where(:name, "Nico")
        .query_one(&.read(String))
    }
  end

  it "scalar!" do
    new_query_executor
      .find(:tests)
      .select(:name)
      .where(:name, "Nico")
      .scalar!.as(String)
      .should eq("Nico")

    new_query_executor
      .find(:tests)
      .count(:name)
      .scalar!.as(Int64)
      .should eq(1)

    expect_raises(DB::NoResultsError) {
      new_query_executor
        .find(:tests)
        .select(:name)
        .where(:name, "Terminator")
        .scalar!.as(String)
    }

    new_query_executor
      .find(:tests)
      .count(:name)
      .where(:name, "Terminator")
      .scalar!.as(Int64)
      .should eq(0)
  end

  it "scalar" do
    new_query_executor
      .find(:tests)
      .select(:name)
      .where(:name, "Nico")
      .scalar.as(String)
      .should eq("Nico")

    new_query_executor
      .find(:tests)
      .count(:name)
      .scalar.as(Int64)
      .should eq(1)

    new_query_executor
      .find(:tests)
      .select(:name)
      .where(:name, "Terminator")
      .scalar.as(String?)
      .should be_nil

    new_query_executor
      .find(:tests)
      .count(:name)
      .where(:name, "Terminator")
      .scalar.as(Int64)
      .should eq(0)
  end

  it "raw_query(&block)" do
    # reset
    drop_table_test
    create_table_test

    expect_raises(DB::NoResultsError) do
      new_query_executor.raw_query {
        %(SELECT name, age FROM tests WHERE name = #{arg("Nico")})
      }.to_o!({name: String, age: Int32})
    end

    insert_table_test

    new_query_executor.raw_query {
      %(SELECT name, age FROM tests WHERE name = #{arg("Nico")})
    }
      .to_o!({name: String, age: Int32})
      .should eq({name: "Nico", age: 38})
  end

  it "build" do
    if ADAPTER_NAME == :pg
      expected_sql = %(SELECT * FROM "tests" WHERE "id" = $1 LIMIT $2)
    else
      expected_sql = %(SELECT * FROM "tests" WHERE "id" = ? LIMIT ?)
    end

    sql, args = new_query_executor.table(:tests).find(:id, 2).limit(1).build
    norm(sql).should eq expected_sql
    args.should eq [2, 1]
  end

  describe "shortcuts" do
    it "to_o!(as types)" do
      insert_table_test
      expect_raises(DB::Error, "more than one row") {
        new_query_executor.find(:tests).select(:name, :age)
          .to_o!({name: String, age: Int32})
      }

      expect_raises(DB::NoResultsError) {
        new_query_executor.find(:tests).select(:name, :age).where(:id, 0)
          .to_o!({name: String, age: Int32})
      }

      new_query_executor.find(:tests).select(:name, :age).limit(1)
        .to_o!({name: String, age: Int32})
        .should eq({name: "Nico", age: 38})
    end

    it "to_o(as types)" do
      insert_table_test
      expect_raises(DB::Error, "more than one row") {
        new_query_executor.find(:tests).select(:name, :age)
          .to_o({name: String, age: Int32})
      }

      new_query_executor.find(:tests).select(:name, :age).where(:id, 0)
        .to_o({name: String, age: Int32})
        .should be_nil

      new_query_executor.find(:tests).select(:name, :age).limit(1)
        .to_o({name: String, age: Int32})
        .should eq({name: "Nico", age: 38})
    end

    it "to_o!(&block)" do
      new_query_executor
        .find(:tests)
        .select(:name)
        .where(:name, "Nico")
        .to_o!(&.read(String))
        .should eq("Nico")

      expect_raises(DB::NoResultsError) {
        new_query_executor
          .find(:tests)
          .select(:name)
          .where(:name, "Terminator")
          .to_o!(&.read(String))
      }

      insert_table_test
      expect_raises(DB::Error, "more than one row") {
        new_query_executor
          .find(:tests)
          .select(:name)
          .where(:name, "Nico")
          .to_o!(&.read(String))
      }
    end

    it "to_o(&block)" do
      new_query_executor
        .find(:tests)
        .select(:name)
        .where(:name, "Nico")
        .to_o(&.read(String))
        .should eq("Nico")

      new_query_executor
        .find(:tests)
        .select(:name)
        .where(:name, "Terminator")
        .to_o(&.read(String))
        .should be_nil

      insert_table_test
      expect_raises(DB::Error, "more than one row") {
        new_query_executor
          .find(:tests)
          .select(:name)
          .where(:name, "Nico")
          .to_o(&.read(String))
      }
    end

    it "to_a(as types)" do
      new_query_executor.find(:tests).select(:name, :age)
        .to_a({name: String, age: Int32})
        .should eq([{name: "Nico", age: 38}])

      insert_table_test(name: "DBX", age: 1)

      new_query_executor.find(:tests).select(:name, :age)
        .to_a({name: String, age: Int32})
        .should eq([{name: "Nico", age: 38}, {name: "DBX", age: 1}])

      tests = new_query_executor.find(:tests).select(:name, :age).where(:id, 0)
        .to_a({name: String, age: Int32})
      tests.should be_a Array({name: String, age: Int32})
      tests.size.should eq 0
    end

    it "to_a(&block)" do
      new_query_executor.find(:tests).select(:name)
        .to_a(&.read(String))
        .should eq(["Nico"])

      insert_table_test(name: "DBX", age: 1)

      new_query_executor.find(:tests).select(:name)
        .to_a(&.read(String))
        .should eq(["Nico", "DBX"])

      new_query_executor.find(:tests).select(:name, :age)
        .to_a { |rs|
          [rs.read(String), rs.read(Int32)]
        }
        .should eq([["Nico", 38], ["DBX", 1]])

      new_query_executor.find(:tests).select(:name, :age)
        .to_a { |rs|
          {name: rs.read(String), age: rs.read(Int32)}
        }
        .should eq([{name: "Nico", age: 38}, {name: "DBX", age: 1}])

      tests = new_query_executor.find(:tests).select(:name).where(:id, 0)
        .to_a(&.read(String))
      tests.should be_a Array(String)
      tests.size.should eq 0
    end
  end
end
