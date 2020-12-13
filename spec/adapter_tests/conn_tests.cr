# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "../spec_helper"

describe DBX do
  it "implements utilities classes" do
    DBX::Error.should be_a DB::Error.class
    DBX::Error.should be_a Exception.class
    DBX::NotSupportedError.should be_a NotImplementedError.class
    DBX::NotSupportedError.should be_a Exception.class
  end

  describe "Connection" do
    before_all do
      DBX.destroy
      DBX.dbs.size.should eq 0
    end

    after_each do
      DBX.destroy
      DBX.dbs.size.should eq 0
    end

    it "dbs containter" do
      DBX.dbs.size.should eq 0
      DBX.dbs.should be_a Hash(String, DB::Database)
      DBX.open("app", ENV["DB_URI"], strict: true)
      DBX.dbs.size.should eq 1
    end

    it "opens a connection" do
      DBX.dbs.size.should eq 0
      DBX.pool_open_connections("app").should eq 0
      DBX.open("app", ENV["DB_URI"], strict: true)
      DBX.dbs.size.should eq 1
      DBX.pool_open_connections("app").should eq 1
    end

    it "closes a connection" do
      DBX.db?("app").should be_false
      DBX.pool_open_connections("app").should eq 0

      DBX.open("app", ENV["DB_URI"], strict: true)
      DBX.db?("app").should be_true
      DBX.pool_open_connections("app").should eq 1

      DBX.destroy("app")
      DBX.db?("app").should be_false
      DBX.pool_open_connections("app").should eq 0
    end

    context "Multi connections" do
      it "open many connections" do
        DBX.open("app1", ENV["DB_URI"], strict: true)
        DBX.db?("app1").should be_true
        DBX.dbs.size.should eq 1

        DBX.open("app2", ENV["DB_URI"], strict: true)
        DBX.db?("app2").should be_true
        DBX.dbs.size.should eq 2

        DBX.open("app3", ENV["DB_URI"], strict: true)
        DBX.db?("app3").should be_true
        DBX.dbs.size.should eq 3

        DBX.open("app4", ENV["DB_URI"], strict: true)
        DBX.db?("app4").should be_true
        DBX.dbs.size.should eq 4
      end

      it "closes connections sequentially" do
        DBX.pool_open_connections("app").should eq 0
        DBX.open("app1", ENV["DB_URI"], strict: true)
        DBX.open("app2", ENV["DB_URI"], strict: true)
        DBX.open("app3", ENV["DB_URI"], strict: true)
        DBX.open("app4", ENV["DB_URI"], strict: true)
        DBX.dbs.size.should eq 4

        DBX.destroy("app1")
        DBX.db?("app1").should be_false
        DBX.dbs.size.should eq 3

        DBX.destroy("app2")
        DBX.db?("app2").should be_false
        DBX.dbs.size.should eq 2

        DBX.destroy("app3")
        DBX.db?("app3").should be_false
        DBX.dbs.size.should eq 1

        DBX.destroy("app4")
        DBX.db?("app4").should be_false
        DBX.dbs.size.should eq 0
      end
    end
  end
end
