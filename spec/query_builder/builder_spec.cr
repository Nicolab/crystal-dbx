# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "./spec_helper"

describe DBX::QueryBuilder do
  builder = BUILDER

  it "should be pre-configured, works without adapter" do
    sql, args = DBX::QueryBuilder.new
      .find("test")
      .select("id AS UUID, title AS name, status")
      .where(:online, true)
      .where("status", "Happy")
      .order_by("id", "desc")
      .offset(10)
      .limit(10)
      .build

    sql.should be_a(String)
    args.should be_a(DBX::QueryBuilder::ArgsType)

    norm(sql).should eq norm(
      %(SELECT "id" AS "UUID", "title" AS "name", "status"
      FROM "test"
      WHERE "online" = ? AND "status" = ?
      ORDER BY "id" DESC LIMIT ? OFFSET ?)
    )
  end

  it "query count" do
    queries_count = count_query(count: false)
    queries_count.should be > 42
    builder.query_count.should eq count_query(count: false)

    # + 1 query
    builder.table("test").find.build
    count_query
    builder.query_count.should eq count_query(count: false)
    builder.query_count.should eq queries_count + 1

    # When reset query
    builder.reset_query
    builder.query_count.should eq count_query(count: false)
    builder.query_count.should eq queries_count + 1
  end
end
