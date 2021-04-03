# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "../spec_helper"

describe DBX::ORM::Schema do
  it ".table_name" do
    Test2::Schema.table_name.should eq "tests"
    TestPK::Schema.table_name.should eq "tests"
    User::Schema.table_name.should eq "users"
  end

  it ".model_class" do
    Test2::Schema.model_class.should eq Test2
    TestPK::Schema.model_class.should eq TestPK
    User::Schema.model_class.should eq User
  end

  it ".fields" do
    Test::Schema.fields.keys.should eq ["Test.id", "Test.name", "Test.about", "Test.age"]
    TestPK::Schema.fields.keys.should eq ["TestPK.uid", "TestPK.name", "TestPK.about", "TestPK.age"]
    User::Schema.fields.keys.should eq ["User.id", "User.username", "User.profile_id"]

    Test::Schema.fields.should eq({
      "Test.id" => {
        name:     "id",
        rel_name: "__Test_id",
        sql:      "tests.id",
        rel_sql:  "tests.id AS __Test_id",
      },
      "Test.name" => {
        name:     "name",
        rel_name: "__Test_name",
        sql:      "tests.name",
        rel_sql:  "tests.name AS __Test_name",
      },
      "Test.about" => {
        name:     "about",
        rel_name: "__Test_about",
        sql:      "tests.about",
        rel_sql:  "tests.about AS __Test_about",
      },
      "Test.age" => {
        name:     "age",
        rel_name: "__Test_age",
        sql:      "tests.age",
        rel_sql:  "tests.age AS __Test_age",
      },
    })

    TestPK::Schema.fields.should eq({
      "TestPK.uid" => {
        name:     "uid",
        rel_name: "__TestPK_uid",
        sql:      "tests.uid",
        rel_sql:  "tests.uid AS __TestPK_uid",
      },
      "TestPK.name" => {
        name:     "name",
        rel_name: "__TestPK_name",
        sql:      "tests.name",
        rel_sql:  "tests.name AS __TestPK_name",
      },
      "TestPK.about" => {
        name:     "about",
        rel_name: "__TestPK_about",
        sql:      "tests.about",
        rel_sql:  "tests.about AS __TestPK_about",
      },
      "TestPK.age" => {
        name:     "age",
        rel_name: "__TestPK_age",
        sql:      "tests.age",
        rel_sql:  "tests.age AS __TestPK_age",
      },
    })

    User::Schema.fields.should eq ({
      "User.id" => {
        name:     "id",
        rel_name: "__User_id",
        sql:      "users.id",
        rel_sql:  "users.id AS __User_id",
      },
      "User.username" => {
        name:     "username",
        rel_name: "__User_username",
        sql:      "users.username",
        rel_sql:  "users.username AS __User_username",
      },
      "User.profile_id" => {
        name:     "profile_id",
        rel_name: "__User_profile_id",
        sql:      "users.profile_id",
        rel_sql:  "users.profile_id AS __User_profile_id",
      },
    })
  end

  it ".sql_fields" do
    Test::Schema.sql_fields.should eq "tests.id,tests.name,tests.about,tests.age"
    Test2::Schema.sql_fields.should eq "tests.id,tests.name,tests.about,tests.age"
    TestPK::Schema.sql_fields.should eq "tests.uid,tests.name,tests.about,tests.age"
    User::Schema.sql_fields.should eq "users.id,users.username,users.profile_id"
  end

  it ".sql_rel_fields" do
    Test::Schema.sql_rel_fields.should eq(
      "tests.id AS __Test_id,tests.name AS __Test_name,tests.about AS __Test_about,tests.age AS __Test_age"
    )

    Test2::Schema.sql_rel_fields.should eq(
      "tests.id AS __Test2_id,tests.name AS __Test2_name,tests.about AS __Test2_about,tests.age AS __Test2_age"
    )

    TestPK::Schema.sql_rel_fields.should eq(
      "tests.uid AS __TestPK_uid,tests.name AS __TestPK_name,tests.about AS __TestPK_about,tests.age AS __TestPK_age"
    )

    User::Schema.sql_rel_fields.should eq(
      "users.id AS __User_id,users.username AS __User_username,users.profile_id AS __User_profile_id"
    )
  end

  pending ".from_rs" do
    User
  end
end
