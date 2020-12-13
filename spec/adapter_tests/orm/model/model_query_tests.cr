# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "../spec_helper"

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

  it "should execute CRUD: insert, find, select, update, delete" do
    data = {name: "test_insert", about: "Crystal is awesome!", age: 10}

    Test.insert(data).exec!.rows_affected.should eq 1

    # Test with query_one and Schema
    test = Test
      .find
      .select(:name, :about, :age)
      .where(:name, "test_insert")
      .limit(1)
      .query_one!(as: Test::Schema)

    test.id.should eq nil # <= not selected
    {name: test.name, about: test.about, age: test.age}.should eq data

    # Test with query_one! (using model type by default)
    test = Test
      .find
      .select(:name, :about, :age)
      .where(:name, "test_insert")
      .limit(1)
      .query_one!

    test.id.should eq nil # <= not selected
    {name: test.name, about: test.about, age: test.age}.should eq data

    Test.update({name: "test_update"}).where(:name, test.name).exec!
      .rows_affected.should eq 1

    # Tests custom method (select_all)
    Test.find.select_all.where(:name, "test_update").to_o!.id.should be_a(Int64)

    Test.delete.where(:name, "test_update").exec!
      .rows_affected.should eq 1
  end

  # ----------------------------------------------------------------------------

  it "build" do
    if ADAPTER_NAME == :pg
      expected_sql = %(SELECT * FROM "tests" WHERE "id" = $1 LIMIT $2)
    else
      expected_sql = %(SELECT * FROM "tests" WHERE "id" = ? LIMIT ?)
    end

    sql, args = Test.find(2).limit(1).build
    norm(sql).should eq expected_sql
    args.should eq [2, 1]
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

  describe "ModelMixin" do
    it "query : DBX::QueryExecutor" do
      insert_table_test(name: "DBX", age: 1)

      Test.query.should be_a DBX::QueryExecutor

      # Should be a new instance
      Test.query.should_not eq Test.query

      Test.query.find.select(:name).to_a(&.read(String))
        .should eq(["Nico", "DBX"])

      Test.query.find.select(:name, :age).to_a(as: {name: String, age: Int32})
        .should eq([{name: "Nico", age: 38}, {name: "DBX", age: 1}])

      test = Test.query.create(
        {name: "created", about: "about", age: 1},
        as: {String, Int32},
        returning: {:name, :age}
      )
      test.should_not be_a Test::Schema
      test.should be_a({String, Int32})
      test.should eq({"created", 1})
      Test.find.where(:name, "created").to_o!.id.should_not be_nil

      test = Test.query.create(
        {name: "created2", about: "about", age: 1},
        as: {name: String, age: Int32},
        returning: {:name, :age}
      )
      test.should_not be_a Test::Schema
      test.should be_a({name: String, age: Int32})
      test.should eq({name: "created2", age: 1})
      Test.find.where(:name, "created2").to_o!.id.should_not be_nil
    end

    it "find" do
      tests = Test.find.to_a
      tests.should be_a Array(Test::Schema)
      tests.size.should eq 1
      tests.first.name.should eq "Nico"
    end

    it "find(pk_value)" do
      expected = Test.find.to_a.first
      test = Test.find(expected.id).to_o!
      test.should be_a Test::Schema
      test.id.should eq expected.id
      test.name.should eq expected.name
      test.age.should eq expected.age
      test.about.should eq expected.about
    end

    it "insert(data : Hash | NamedTuple)" do
      Test.insert({name: "DBX Query builder", about: "Like SQL with super power", age: 0}).exec!
        .rows_affected.should eq 1
      Test.insert({"name" => "DBX ORM", "about" => "Flexible ORM", "age" => 0}).exec!
        .rows_affected.should eq 1

      tests = Test.find.like("name", "DBX%").order_by(:name).to_a
      tests.size.should eq 2
      tests[0].name.should eq "DBX ORM"
      tests[1].name.should eq "DBX Query builder"
    end

    it "create" do
      data = {name: "DBX Query builder", about: "Like SQL with super power", age: 0}
      test = Test.create(data)
      test.should be_a Test::Schema
      test.id.not_nil!.should be > 1
      test.name.should eq data[:name]
      test.about.should eq data[:about]
      test.age.should eq data[:age]

      Test.find(test.id).to_o!.id.should eq test.id

      test = Test.create(data, {:name, :about, :age})
      test.should be_a Test::Schema
      test.id.should be_nil
      test.name.should eq data[:name]
      test.about.should eq data[:about]
      test.age.should eq data[:age]
    end

    it "update(data : Hash | NamedTuple)" do
      test = Test.find.limit(1).to_o!
      test.name.should eq "Nico"

      Test.update({name: "named tuple"}).where(:id, test.id).exec!.rows_affected.should eq 1
      test = Test.find(test.id).to_o!
      test.name.should eq "named tuple"

      Test.update({"name" => "hash"}).where(:id, test.id).exec!.rows_affected.should eq 1
      test = Test.find(test.id).to_o!
      test.name.should eq "hash"
    end

    it "update(pk_value, data : Hash | NamedTuple)" do
      test = Test.find.limit(1).to_o!
      test.name.should eq "Nico"

      Test.update(test.id, {name: "named tuple"}).exec!.rows_affected.should eq 1
      test = Test.find(test.id).to_o!
      test.name.should eq "named tuple"

      Test.update(test.id, {"name" => "hash"}).exec!.rows_affected.should eq 1
      test = Test.find(test.id).to_o!
      test.name.should eq "hash"
    end

    it "delete" do
      insert_table_test
      test = Test.find.limit(1).to_o!
      test.id.not_nil!.should be >= 1
      Test.delete.where(:id, test.id).exec!.rows_affected.should eq 1
      Test.find(test.id).to_o.should be_nil
    end

    it "delete(pk_value)" do
      insert_table_test
      test = Test.find.limit(1).to_o!
      test.id.not_nil!.should be >= 1
      Test.find.count(:id).scalar!.as(Int64).should eq 2
      Test.delete(test.id).exec!.rows_affected.should eq 1
      Test.find(test.id).to_o.should be_nil
      Test.find.count(:id).scalar!.as(Int64).should eq 1
    end
  end

  describe "shortcuts" do
    it "to_o!" do
      test = Test.find.limit(1).to_o!
      test.should be_a Test::Schema
      test.id.should be_a Int64
      test.id.not_nil!.should be >= 1
      test.name.should eq "Nico"

      # reset
      drop_table_test
      create_table_test

      expect_raises(DB::NoResultsError) {
        Test.find.to_o!
      }

      insert_table_test
      insert_table_test

      expect_raises(DB::Error, "more than one row") {
        Test.find.to_o!
      }
    end

    it "to_o" do
      raise "DB entry not found" unless test = Test.find.limit(1).to_o

      test.should be_a Test::Schema
      test.id.should be_a Int64
      test.id.not_nil!.should be >= 1
      test.name.should eq "Nico"

      # reset
      drop_table_test
      create_table_test

      Test.find.to_o.should be_nil

      insert_table_test
      insert_table_test

      expect_raises(DB::Error, "more than one row") {
        Test.find.to_o
      }
    end

    it "to_o!(as types)" do
      test = Test.find.select(:name, :age).limit(1)
        .to_o!({name: String, age: Int32})

      test.should_not be_a Test::Schema
      test.should eq({name: "Nico", age: 38})

      # reset
      drop_table_test
      create_table_test

      expect_raises(DB::NoResultsError) {
        Test.find.select(:name, :age).limit(1)
          .to_o!({name: String, age: Int32})
      }

      insert_table_test
      insert_table_test

      expect_raises(DB::Error, "more than one row") {
        Test.find.select(:name, :age)
          .to_o!({name: String, age: Int32})
      }
    end

    it "to_o(as types)" do
      raise "DB entry not found" unless test = Test.find.select(:name, :age).limit(1)
                                          .to_o({name: String, age: Int32})

      test.should_not be_a Test::Schema
      test.should eq({name: "Nico", age: 38})

      # reset
      drop_table_test
      create_table_test

      Test.find.select(:name, :age).limit(1)
        .to_o({name: String, age: Int32})
        .should be_nil

      insert_table_test
      insert_table_test

      expect_raises(DB::Error, "more than one row") {
        Test.find.select(:name, :age)
          .to_o({name: String, age: Int32})
      }
    end

    it "to_a" do
      tests = Test.find.to_a
      tests.should be_a Array(Test::Schema)
      tests.size.should eq 1
      tests.first.id.should be_a Int64
      tests.first.id.not_nil!.should be >= 1
      tests.first.name.should eq "Nico"
      tests.first.age.should eq 38
      tests.first.about.should eq "Lives in Biarritz"

      insert_table_test(name: "DBX", age: 1, about: "Great ORM :)")

      tests = Test.find.order_by(:id, :ASC).to_a
      tests.should be_a Array(Test::Schema)
      tests.size.should eq 2

      tests[0].id.should be_a Int64
      tests[0].id.not_nil!.should be >= 1
      tests[0].name.should eq "Nico"
      tests[0].age.should eq 38
      tests[0].about.should eq "Lives in Biarritz"

      tests[1].id.should be_a Int64
      tests[1].id.not_nil!.should be >= 2
      tests[1].name.should eq "DBX"
      tests[1].age.should eq 1
      tests[1].about.should eq "Great ORM :)"

      tests = Test.find.select(:name, :age).where(:id, 0).to_a
      tests.should be_a Array(Test::Schema)
      tests.size.should eq 0
    end

    it "to_a(as types)" do
      Test.find.select(:name, :age)
        .to_a({name: String, age: Int32})
        .should eq([{name: "Nico", age: 38}])

      insert_table_test(name: "DBX", age: 1)

      Test.find.select(:name, :age)
        .to_a({name: String, age: Int32})
        .should eq([{name: "Nico", age: 38}, {name: "DBX", age: 1}])

      tests = Test.find.select(:name, :age).where(:id, 0)
        .to_a({name: String, age: Int32})
      tests.should be_a Array({name: String, age: Int32})
      tests.size.should eq 0
    end
  end
end
