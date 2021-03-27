# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "./spec_helper"

macro def_insert_tests(data)
  sql, args = builder.table(:test).insert(data).build
    count_query

    norm(sql).should eq norm(%(
      INSERT INTO test (title, slug, content, tags, time, status, null)
      VALUES ($1, $2, $3, $4, $5, $6, $7))
    )

    args.should eq data.values.to_a

    # Insert with table
    sql, args = builder.insert(:test, data).build
    count_query

    norm(sql).should eq norm(%(
      INSERT INTO test (title, slug, content, tags, time, status, null)
      VALUES ($1, $2, $3, $4, $5, $6, $7))
    )

    args.should eq data.values.to_a
end

macro def_update_tests(data)
  sql, args = builder.table("test").update(data).where("id", 42).build
    count_query

    norm(sql).should eq norm(%(UPDATE test
      SET
        title = $1,
        slug = $2,
        content = $3,
        tags = $4,
        time = $5,
        status = $6,
        null = $7
      WHERE id = $8)
    )

    args.should eq data.values.to_a.push(42)

    # Update with table
    sql, args = builder.update(:test, data).where("id", 42).build
    count_query

    norm(sql).should eq norm(%(UPDATE test
      SET
        title = $1,
        slug = $2,
        content = $3,
        tags = $4,
        time = $5,
        status = $6,
        null = $7
      WHERE id = $8)
    )

    args.should eq data.values.to_a.push(42)

    # Update with PK
    sql, args = builder.table(:test).update(:id, 42, data).build
    count_query

    norm(sql).should eq norm(%(UPDATE test
      SET
        title = $1,
        slug = $2,
        content = $3,
        tags = $4,
        time = $5,
        status = $6,
        null = $7
      WHERE id = $8)
    )

    args.should eq data.values.to_a.push(42)
end

describe DBX::QueryBuilder do
  builder = BUILDER

  describe "find" do
    it "find(table_name : OneOrMoreFieldsType)" do
      # One
      query = builder.find(:test1)
      query.table.should eq "test1"
      sql, args = query.build
      count_query
      norm(sql).should eq %(SELECT * FROM test1)
      args.size.should eq 0

      # More
      query = builder.find({:test1, :test2})
      query.table.should eq "test1, test2"
      sql, args = query.build
      count_query
      norm(sql).should eq %(SELECT * FROM test1, test2)
      args.should be_a(DBX::QueryBuilder::ArgsType)
      args.should be_a(Array(DBX::QueryBuilder::DBValue))
      args.size.should eq 0
    end

    it "find(&block)" do
      query = builder.find { "#{q("posts")} AS p, articles a" }
      query.table.should eq %("posts" AS p, articles a)
      sql, args = query.build
      count_query
      norm(sql).should eq %(SELECT * FROM "posts" AS p, articles a)
      args.should be_a(DBX::QueryBuilder::ArgsType)
      args.should be_a(Array(DBX::QueryBuilder::DBValue))
      args.size.should eq 0
    end
  end

  it "delete" do
    sql, args = builder.delete(:test).where(:id, 17).build
    count_query
    norm(sql).should eq %(DELETE FROM test WHERE id = $1)
    args.should eq [17]

    # With pk
    sql, args = builder.table(:test).delete(:id, 17).build
    count_query
    norm(sql).should eq %(DELETE FROM test WHERE id = $1)
    args.should eq [17]
  end

  it "delete truncate" do
    sql, args = builder.delete(:test).build
    count_query
    sql.should eq %(TRUNCATE TABLE test)
    args.size.should eq 0
  end

  it "insert method with Hash" do
    data = {
      "title"   => "query builder for Crystal",
      "slug"    => "query-builder-for-crystal",
      "content" => "SQL query builder library for crystal-lang...",
      "tags"    => "Crystal, ORM, query, builder",
      "time"    => Time.utc(2020, 12, 28).to_s("%Y-%m-%d %H:%M:%S"),
      "status"  => 1,
      "null"    => nil,
    }

    def_insert_tests(data)
  end

  it "insert method with NamedTuple" do
    data = {
      title:   "query builder for Crystal",
      slug:    "query-builder-for-crystal",
      content: "SQL query builder library for crystal-lang...",
      tags:    "Crystal, ORM, query, builder",
      time:    Time.utc(2020, 12, 28).to_s("%Y-%m-%d %H:%M:%S"),
      status:  1,
      null:    nil,
    }

    def_insert_tests(data)
  end

  it "update method (Array)" do
    data = {
      "title"   => "Craft",
      "slug"    => "craft-framework",
      "content" => "Framework for happy dev!",
      "tags"    => "crystal, framework, craft",
      "time"    => Time.utc(2020, 12, 28).to_s("%Y-%m-%d %H:%M:%S"),
      "status"  => 1,
      "null"    => nil,
    }

    def_update_tests(data)
  end

  it "update method (Tuple)" do
    data = {
      title:   "Craft",
      slug:    "craft-framework",
      content: "Framework for happy dev!",
      tags:    "crystal, framework, craft",
      time:    Time.utc(2020, 12, 28).to_s("%Y-%m-%d %H:%M:%S"),
      status:  1,
      null:    nil,
    }

    def_update_tests(data)
  end
end
