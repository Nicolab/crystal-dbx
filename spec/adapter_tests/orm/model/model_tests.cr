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
    Test::ModelQuery.should be_a DBX::Query.class
    Test::Schema.should_not be_nil
    Test::Error.should be_a DBX::Error.class
    Test::Error.should be_a DB::Error.class
    Test.connection.should eq "app"
    Test.table_name.should eq "tests"
    Test.pk_name.should eq "id"
    Test.fk_name.should eq "test_id"
  end

  it "customizes table name" do
    db_open "test2"

    Test.connection.should eq "app"
    Test2.connection.should eq "test2"

    Test.table_name.should eq "tests"
    Test2.table_name.should eq "tests"

    Test.pk_name.should eq "id"
    Test2.pk_name.should eq "id"

    Test.fk_name.should eq "test_id"
    Test2.fk_name.should eq "test_id"

    Test.find.to_o!.name.should eq "Nico"
    Test2.find.to_o!.name.should eq "Nico"
  end

  it "customizes primary key and foreign key" do
    db_open "test"
    drop_table_test
    create_table_test_with_custom_pk
    insert_table_test_with_custom_pk("abc")

    Test.connection.should eq "app"
    TestPK.connection.should eq "app"

    Test.table_name.should eq "tests"
    TestPK.table_name.should eq "tests"

    Test.pk_name.should eq "id"
    TestPK.pk_name.should eq "uid"

    Test.fk_name.should eq "test_id"
    Test.pk_type.should eq Int64
    TestPK.fk_name.should eq "test_uid"
    TestPK.pk_type.should eq String

    test = TestPK.find.to_o!
    test.name.should eq "Nico"

    test2 = TestPK.find("abc").to_o!
    test2.uid.should eq "abc"
    test2.uid.should eq test.uid
  end
end
