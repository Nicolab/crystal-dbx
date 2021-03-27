# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "./spec_helper"

macro def_maintenance_tests(command_sql)
  {% begin %}
    query = builder.table("test").{{command_sql.id}}
    query.table.should eq "test"
    sql, args = query.build
    count_query
    sql.should be_a(String)
    norm(sql).should eq %({{command_sql.upcase.id}} TABLE test)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0

    # Multi tables
    query = builder.table(["foo", "bar", "baz"]).{{command_sql.id}}
    count_query
    query.table.should eq "foo, bar, baz"
    sql, args = query.build
    sql.should be_a(String)
    norm(sql).should eq %({{command_sql.upcase.id}} TABLE foo, bar, baz)
    args.should be_a(DBX::QueryBuilder::ArgsType)
    args.should be_a(Array(DBX::QueryBuilder::DBValue))
    args.size.should eq 0
  {% end %}
end

describe "DBX::QueryBuilder maintenance" do
  builder = BUILDER

  it "analyze" do
    def_maintenance_tests("analyze")
  end

  it "check" do
    def_maintenance_tests("check")
  end

  it "checksum" do
    def_maintenance_tests("checksum")
  end

  it "optimize" do
    def_maintenance_tests("optimize")
  end

  it "repair" do
    def_maintenance_tests("repair")
  end
end
