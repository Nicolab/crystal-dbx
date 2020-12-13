# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "../spec_helper"

describe DBX::ORM::Model do
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

  it "model instance" do
    Test.new
    Test::ModelQuery.should be_a DBX::QueryExecutor.class
    Test::Schema.should_not be_nil
    Test::Error.should be_a DBX::Error.class
    Test::Error.should be_a DB::Error.class
    Test.db_entry.should eq "app"
    Test.table_name.should eq "tests"
    Test.pk_name.should eq "id"
    Test.foreign_key_name.should eq "test_id"
  end

  it "customizes table name" do
    db_open "test2"

    Test.db_entry.should eq "app"
    Test2.db_entry.should eq "test2"

    Test.table_name.should eq "tests"
    Test2.table_name.should eq "tests"

    Test.pk_name.should eq "id"
    Test2.pk_name.should eq "id"

    Test.foreign_key_name.should eq "test_id"
    Test2.foreign_key_name.should eq "test_id"

    Test.find.to_o!.name.should eq "Nico"
    Test2.find.to_o!.name.should eq "Nico"
  end
end
