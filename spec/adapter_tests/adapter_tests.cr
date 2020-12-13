# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "../spec_helper"

describe DBX::Adapter do
  it "QueryBuilder" do
    DBAdapter::QueryBuilder.should be_a DBX::QueryBuilder.class
  end

  it "new_builder" do
    DBAdapter.new_builder.should be_a DBX::QueryBuilder
    DBAdapter.new_builder.should be_a DBAdapter::QueryBuilder

    dba = DBAdapter.new(db_open)
    dba.new_builder.should be_a DBX::QueryBuilder
    dba.new_builder.should be_a DBAdapter::QueryBuilder
  end

  it "builder_class" do
    DBAdapter.builder_class.should eq DBAdapter::QueryBuilder

    dba = DBAdapter.new(db_open)
    dba.builder_class.should be_a DBX::QueryBuilder.class
    dba.builder_class.should eq DBAdapter::QueryBuilder
  end

  it "db" do
    DBAdapter.new(db_open).db.should be_a DB::Database
  end

  it "create" do
    {{ DBAdapter.has_method?(:create) }}.should be_true
  end
end
