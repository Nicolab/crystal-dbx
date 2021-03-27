# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "./spec_helper"

describe "DBX::QueryBuilder select" do
  builder = BUILDER

  it "selects * from table" do
    builder.find("test").build.first.should eq %(SELECT * FROM test)
    count_query

    builder.table("test").find.select("*").build.first.should eq %(SELECT * FROM test)
    count_query

    builder.table("test").select("*").find.build.first.should eq %(SELECT * FROM test)
    count_query
  end

  it "select given fields from table" do
    builder.find("test").select("id as uid, title, content, status").build.first
      .should eq %(SELECT id as uid, title, content, status FROM test)
    count_query
  end

  it "select given fields from table (variadic)" do
    builder.find("test").select("id as uid", :title, "content", :status).build.first
      .should eq %(SELECT id as uid, title, content, status FROM test)
    count_query
  end

  it "select given fields from table (tuple)" do
    builder.find("test").select({"id as uid", :title, "content", :status}).build.first
      .should eq %(SELECT id as uid, title, content, status FROM test)
    count_query
  end

  it "select given fields from table (array)" do
    builder.find("test").select(["id as uid", :title, "content", :status]).build.first
      .should eq %(SELECT id as uid, title, content, status FROM test)
    count_query
  end

  it "select functions (max, min, count, sum, avg)" do
    builder.find("test").max("price", "maxPrice").build.first
      .should eq %(SELECT MAX(price) AS maxPrice FROM test)
    count_query

    builder.find("test").min("price", "minPrice").build.first
      .should eq %(SELECT MIN(price) AS minPrice FROM test)
    count_query

    builder.find("test").count("price", "countPrice").build.first
      .should eq %(SELECT COUNT(price) AS countPrice FROM test)
    count_query

    builder.find("test").count("connected").build.first
      .should eq %(SELECT COUNT(connected) FROM test)
    count_query

    builder.find("test").count("DISTINCT city").build.first
      .should eq %(SELECT COUNT(DISTINCT city) FROM test)
    count_query

    builder.find("test").count("*").build.first
      .should eq %(SELECT COUNT(*) FROM test)
    count_query

    builder.find("test").sum("price", "sumPrice").build.first
      .should eq %(SELECT SUM(price) AS sumPrice FROM test)
    count_query

    builder.find("test").avg("price", "avgPrice").build.first
      .should eq %(SELECT AVG(price) AS avgPrice FROM test)
    count_query
  end

  it "sql join" do
    norm(builder.find("test")
      .join(:foo, "test.id", "foo.test_id")
      .inner_join(:bar, :baz)
      .join { "CROSS JOIN #{q(:articles)} USING(page_id)" }
      .inner_join("foo1", "test1.id", "foo1.page_id")
      .left_join("foo2", "test2.id", "foo2.page_id")
      .left_outer_join("foo3", "test3.id", "foo3.page_id")
      .right_join("foo4", "test4.id", "foo4.page_id")
      .right_outer_join("foo5", "test5.id", "foo5.page_id")
      .full_join("foo6", "test6.id", "foo6.page_id")
      .full_outer_join("foo7", "test7.id", "foo7.page_id")
      .build.first)
      .should eq norm(%(SELECT * FROM test
        JOIN foo ON test.id = foo.test_id
        INNER JOIN bar ON baz
        CROSS JOIN "articles" USING(page_id)
        INNER JOIN foo1 ON test1.id = foo1.page_id
        LEFT JOIN foo2 ON test2.id = foo2.page_id
        LEFT OUTER JOIN foo3 ON test3.id = foo3.page_id
        RIGHT JOIN foo4 ON test4.id = foo4.page_id
        RIGHT OUTER JOIN foo5 ON test5.id = foo5.page_id
        FULL JOIN foo6 ON test6.id = foo6.page_id
        FULL OUTER JOIN foo7 ON test7.id = foo7.page_id\
      ))
    count_query
  end

  it "where and or_where" do
    sql, args = builder.find("test").where("auth", 1).or_where("auth", 2).build
    count_query
    norm(sql).should eq %(SELECT * FROM test WHERE auth = $1 OR auth = $2)
    args.should eq [1, 2]
  end

  it "where(&block)" do
    sql, args = builder.find("test").where {
      "#{q(:auth)} = #{arg(1)} OR auth = #{arg(2)}"
    }.build
    count_query
    norm(sql).should eq %(SELECT * FROM test WHERE "auth" = $1 OR auth = $2)
    args.should eq [1, 2]
  end

  it "sql where in" do
    sql, args = builder.find("test").where("active", 1).in("id", [1, 2, 3]).build
    count_query
    norm(sql).should eq %(SELECT * FROM test WHERE active = $1 AND id IN ($2, $3, $4))
    args.should eq [1, 1, 2, 3]
  end

  it "sql where between" do
    sql, args = builder.find("test").where("status", 1).between("age", 18, 30).build
    count_query
    norm(sql).should eq %(SELECT * FROM test WHERE status = $1 AND age BETWEEN $2 AND $3)
    args.should eq [1, 18, 30]
  end

  it "sql where like" do
    sql, args = builder.find("test").where("status", 1).like("title", "%crystal%").limit(10).build
    norm(sql).should eq %(SELECT * FROM test WHERE status = $1 AND title LIKE $2 LIMIT $3)
    count_query
    args.should eq [1, "%crystal%", 10]
  end

  it "sql group by" do
    sql, args = builder.find("test").where("status", 1).group_by("cat_id").build
    count_query
    norm(sql).should eq %(SELECT * FROM test WHERE status = $1 GROUP BY cat_id)
    args.should eq [1]
  end

  it "sql having" do
    sql, args = builder
      .find("test")
      .where("status", 1)
      .group_by(:city)
      .having("COUNT(person)", 100)
      .build

    count_query

    norm(sql).should eq norm(%(
      SELECT *
      FROM test
      WHERE status = $1
      GROUP BY city
      HAVING COUNT(person) > $2))

    args.should eq [1, 100]
  end

  it "sql having with block" do
    sql, args = builder
      .find("test")
      .where("status", 1)
      .group_by(:city)
      .having { "SUM(person) > 40" }
      .build

    count_query

    norm(sql).should eq norm(%(
      SELECT *
      FROM test
      WHERE status = $1
      GROUP BY city
      HAVING SUM(person) > 40))

    args.should eq [1]
  end

  it "sql order by" do
    sql, args = builder.find(:test).where(:active, 1).order_by(:id, :desc).limit(5).build
    count_query
    norm(sql).should eq %(SELECT * FROM test WHERE active = $1 ORDER BY id DESC LIMIT $2)
    args.should eq [1, 5]
  end
end
