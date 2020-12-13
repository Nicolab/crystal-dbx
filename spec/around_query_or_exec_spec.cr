# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "./spec_helper"

AROUND_QE_COUNT = Atomic.new(0)

DBX.around_query_or_exec do |args|
  args.should_not be_nil
  res = yield
  res.should_not be_nil
  (res.is_a?(DB::ExecResult) || res.is_a?(DB::ResultSet)).should be_true
  AROUND_QE_COUNT.add 1
  res
end

DBX.around_query_or_exec do |args|
  args.should_not be_nil
  res = yield
  res.should_not be_nil
  (res.is_a?(DB::ExecResult) || res.is_a?(DB::ResultSet)).should be_true
  AROUND_QE_COUNT.add 1
  res
end

describe "dbx_around_query_or_exec" do
  before_each do
    db_open
    create_table_test
  end

  after_each do
    drop_table_test
    DBX.destroy
    DBX.dbs.size.should eq 0
  end

  it "should be called on #exec" do
    count = AROUND_QE_COUNT.get
    insert_table_test
    AROUND_QE_COUNT.get.should be >= (count + 1)
  end

  it "should be called on #query" do
    count = AROUND_QE_COUNT.get
    select_table_test
    AROUND_QE_COUNT.get.should be >= (count + 1)
  end
end
