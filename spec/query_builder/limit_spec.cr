# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "./spec_helper"

describe "DBX::QueryBuilder" do
  builder = BUILDER

  it "limit" do
    query = builder.table("test").where("status", 1).limit(5).offset(10).find
    count_query
    query.limit.should eq "$2"
    sql, args = query.build
    norm(sql).should eq %(SELECT * FROM test WHERE status = $1 LIMIT $2 OFFSET $3)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 3
    args[0].should eq 1
    args[1].should eq 5
    args[2].should eq 10

    # Without offset
    query = builder.table("test").where("status", 1).limit(5).find
    count_query
    query.limit.should eq "$2"
    query.offset.should eq ""
    sql, args = query.build
    norm(sql).should eq %(SELECT * FROM test WHERE status = $1 LIMIT $2)
    args.size.should eq 2
    args[0].should eq 1
    args[1].should eq 5
  end

  it "limit(offset, limit)" do
    query = builder.table("test").where("status", 1).limit(5, 10).find
    count_query
    query.limit.should eq "$2"
    query.offset.should eq "$3"
    sql, args = query.build
    norm(sql).should eq %(SELECT * FROM test WHERE status = $1 LIMIT $2 OFFSET $3)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 3
    args[0].should eq 1
    args[1].should eq 10 # limit
    args[2].should eq 5  # offset
  end

  it "offset" do
    query = builder.table("test").where("status", 1).limit(5).offset(10).find
    count_query
    query.offset.should eq "$3"
    sql, args = query.build
    norm(sql).should eq %(SELECT * FROM test WHERE status = $1 LIMIT $2 OFFSET $3)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 3
    args[0].should eq 1
    args[1].should eq 5
    args[2].should eq 10

    # Without limit
    query = builder.table("test").where("status", 1).offset(5).find
    count_query
    query.offset.should eq "$2"
    query.limit.should eq ""
    sql, args = query.build
    norm(sql).should eq %(SELECT * FROM test WHERE status = $1 OFFSET $2)
    args.size.should eq 2
    args[0].should eq 1
    args[1].should eq 5
  end

  it "limit & offset (order)" do
    query = builder.table("test").where("status", 1).limit(5).offset(10).find
    count_query
    query.limit.should eq "$2"
    query.offset.should eq "$3"
    sql, args = query.build
    norm(sql).should eq %(SELECT * FROM test WHERE status = $1 LIMIT $2 OFFSET $3)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 3
    args[0].should eq 1
    args[1].should eq 5
    args[2].should eq 10

    # inverse
    query = builder.table("test").where("status", 1).offset(10).limit(5).find
    count_query
    query.offset.should eq "$2"
    query.limit.should eq "$3"
    sql, args = query.build
    norm(sql).should eq %(SELECT * FROM test WHERE status = $1 LIMIT $3 OFFSET $2)
    args.size.should eq 3
    args[0].should eq 1
    args[1].should eq 10
    args[2].should eq 5
  end

  it "paginate" do
    # Page 1
    query = builder.table("test").paginate(15, 1).find
    count_query
    query.limit.should eq "$1"
    query.offset.should eq "$2"
    sql, args = query.build
    norm(sql).should eq %(SELECT * FROM test LIMIT $1 OFFSET $2)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 2
    args[0].should eq 15
    args[1].should eq 0

    # Page 2
    query = builder.table("test").paginate(15, 2).find
    count_query
    query.limit.should eq "$1"
    query.offset.should eq "$2"
    sql, args = query.build
    norm(sql).should eq %(SELECT * FROM test LIMIT $1 OFFSET $2)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 2
    args[0].should eq 15
    args[1].should eq 15
  end
end
