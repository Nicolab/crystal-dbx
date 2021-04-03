# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

{% if ADAPTER_NAME == :pg %}
  require "../spec_helper"
  require "../migrations"

  pending "ORM::Model relations" do
    before_each do
      db_open
      MIG.migrate to: 1
    end

    after_each do
      MIG.migrate to: 0
      DBX.destroy
      DBX.dbs.size.should eq 0
    end

    it "one to one" do
      p1 = Profile.create!({name: "p1"})
      p2 = Profile.create!({name: "p2"})

      u1 = User.create!({username: "u1", profile_id: p1.id})
      u2 = User.create!({username: "u2", profile_id: p2.id})
      u3 = User.create!({username: "u3", profile_id: p1.id})

      profile = Profile
        .find(p1._pk!)
        .rel("users")
        .left_join("users", "users.profile_id", "profiles.id")
        .to_o
        .not_nil!

      profile.should be_a Profile::Schema
      profile.id.should eq p1._pk
      profile.id.should eq p1.id
      profile.users.should be_a Array(User::Schema)
      profile.users.size.should eq 2
      profile.users.first.id.should eq u1.id
      profile.users.first.username.should eq u1.username
      profile.users.last.id.should eq u3.id
      profile.users.last.username.should eq u3.username
    end

    it "one to many" do
      p1 = Profile.create!({name: "p1"})
      p2 = Profile.create!({name: "p2"})

      u1 = User.create!({username: "u1", profile_id: p1.id})
      u2 = User.create!({username: "u2", profile_id: p2.id})
      u3 = User.create!({username: "u3", profile_id: p1.id})

      profile = Profile
        .find(p1._pk!)
        .rel("users")
        .left_join("users", "users.profile_id", "profiles.id")
        .to_o
        .not_nil!

      profile.should be_a Profile::Schema
      profile.id.should eq p1._pk
      profile.id.should eq p1.id
      profile.users.should be_a Array(User::Schema)
      profile.users.size.should eq 2
      profile.users.first.id.should eq u1.id
      profile.users.first.username.should eq u1.username
      profile.users.last.id.should eq u3.id
      profile.users.last.username.should eq u3.username
    end

    it "one to many (not found)" do
      Profile.create!({name: "p1"})

      # --

      profile = Profile
        .find
        .rel("users")
        .left_join("users", "users.profile_id", "profiles.id")
        .to_o!

      profile.users.should be_a Array(User::Schema)
      profile.users.size.should eq 0

      # --

      profile = Profile
        .find
        .rel("users")
        .left_join(:users, "users.profile_id", "profiles.id")
        .to_o
        .not_nil!

      profile.users.should be_a Array(User::Schema)
      profile.users.size.should eq 0
    end

    it "many to one" do
      p1 = Profile.create!({name: "p1"})
      p2 = Profile.create!({name: "p2"})
      u1 = User.create!({username: "u1", profile_id: p1.id})
      u2 = User.create!({username: "u2", profile_id: p2.id})
      u3 = User.create!({username: "u3", profile_id: p1.id})
      u4 = User.create!({username: "u4", profile_id: p1.id})

      # --

      users = User
        .find
        .rel("profile")
        .left_join("profiles", "profiles.id", "users.profile_id")
        .where("profiles.id", p1.id)
        .to_a

      users.should be_a Array(User::Schema)
      users.size.should eq 3

      users[0].not_nil!.id.should eq u1.id
      users[0].profile.not_nil!.id.should eq p1.id
      users[1].not_nil!.id.should eq u3.id
      users[1].profile.not_nil!.id.should eq p1.id
      users[2].not_nil!.id.should eq u4.id
      users[2].profile.not_nil!.id.should eq p1.id

      # --

      users = User
        .find
        .rel("profile")
        .left_join("profiles", "profiles.id", "users.profile_id")
        .where("profiles.id", p2.id)
        .to_a

      users.should be_a Array(User::Schema)
      users.size.should eq 1

      users[0].not_nil!.id.should eq u2.id
      users[0].profile.not_nil!.id.should eq p2.id
    end

    it "many to one (not found)" do
      p1 = Profile.create!({name: "p1"})
      p2 = Profile.create!({name: "p2"})
      u1 = User.create!({username: "u1"})
      User.create!({username: "u2", profile_id: p1.id})
      User.create!({username: "u3", profile_id: p1.id})
      User.create!({username: "u4", profile_id: p1.id})

      # --

      users = User
        .find
        .rel("profile")
        .left_join("profiles", "profiles.id", "users.profile_id")
        .where("users.id", u1.id)
        .to_a

      users.should be_a Array(User::Schema)
      users.size.should eq 1
      users.first.id.should eq u1.id
      users.first.profile.should eq nil

      # --

      users = User
        .find
        .rel("profile")
        .left_join("profiles", "profiles.id", "users.profile_id")
        .where("profiles.id", p2.id)
        .to_a

      users.should be_a Array(User::Schema)
      users.size.should eq 0

      # --

      users = User
        .find
        .rel("profile")
        .left_join("profiles", "profiles.id", "users.profile_id")
        .where("profiles.id", 42)
        .to_a

      users.should be_a Array(User::Schema)
      users.size.should eq 0
    end

    pending "many to many" do
      p1 = Profile.create!({name: "p1"})
      p2 = Profile.create!({name: "p2"})
      u1 = User.create!({username: "u1", profile_id: p1.id})
      u2 = User.create!({username: "u2"})
      u3 = User.create!({username: "u3", profile_id: p1.id})

      t1 = Tag.create!({name: "t1", user_id: u1.id})
      t2 = Tag.create!({name: "t2", user_id: u1.id})
      t3 = Tag.create!({name: "t3", user_id: u2.id})
      t4 = Tag.create!({name: "t4", user_id: u2.id})
      t5 = Tag.create!({name: "t5", user_id: u3.id})

      t6 = Tag.create!({name: "t6", profile_id: p1.id, user_id: u1.id})
      t7 = Tag.create!({name: "t7", profile_id: p1.id, user_id: u3.id})

      tags = Tag
        .find
        .rel("users")
        .left_join("users", "users.id", "tags.user_id")
        .where("tags.profile_id", p1.id)
        .to_a

      tags.should be_a Array(Tag::Schema)
      tags.size.should eq 2
      tags.first.id.should eq t6.id
      tags.first.user_id.should eq u1.id
      tags.last.id.should eq t7.id
      tags.last.user_id.should eq u3.id

      # --

      tags = Tag
        .find
        .rel("users")
        .rel("users.profile")
        .left_join("users", "users.id", "tags.user_id")
        .left_join("profiles", "profiles.id", "tags.profile_id")
        .where("tags.user_id", u1.id)
        .order_by("tags.id", "ASC")
        .to_a

      tags.should be_a Array(Tag::Schema)
      tags.size.should eq 3
      tags[0].id.should eq t1.id
      tags[0].profile_id.should eq nil
      tags[0].users.first.profile.should eq nil
      tags[1].id.should eq t2.id
      tags[1].profile_id.should eq nil
      tags[1].users.first.profile.should eq nil
      tags[2].id.should eq t6.id
      tags[2].profile_id.should eq t6.profile_id
      tags[2].users.first.profile.not_nil!.id.should eq t6.profile_id

      # # FIXME: 'profiles' relation should be populated
      # tags = Tag
      #   .find
      #   .rel("users")
      #   .rel("profiles")
      #   .left_join("users", "users.id", "tags.user_id")
      #   .left_join("profiles", "profiles.id", "tags.profile_id")
      #   .where("tags.user_id", u1.id)
      #   .to_a

      #   pp tags
      # tags.should be_a Array(Tag::Schema)
      # # tags.size.should eq 3
    end

    pending "many to many (not found)" do
    end

    it "should prefixe the fields with the table name" do
      sql = Profile.find.rel("users").build.first
      sql.should eq "SELECT profiles.id, profiles.name, users.id, users.username, users.profile_id FROM profiles"
    end

    it "should add aliases to the relation fields" do
      sql = Profile.find.rel("users.profile", :foo).build.first
      sql.should eq "SELECT profiles.id, profiles.name, foo.id, foo.name FROM profiles"

      sql = Profile.find.rel("users.profile", "bar").build.first
      sql.should eq "SELECT profiles.id, profiles.name, bar.id, bar.name FROM profiles"

      sql = Profile.find.rel("users.profile", "foo").rel("users.profile", "bar").build.first
      sql.should eq "SELECT profiles.id, profiles.name, foo.id, foo.name, bar.id, bar.name FROM profiles"
    end

    context "Error" do
      it %(should raise DB::Error: "more than one row") do
        p1 = Profile.create!({name: "p1"})
        p2 = Profile.create!({name: "p2"})
        User.create!({username: "u1", profile_id: p1._pk!})
        User.create!({username: "u2", profile_id: p1._pk!})
        User.create!({username: "u3", profile_id: p2._pk!})

        Profile
          .find
          .rel("users")
          .left_join("users", "users.profile_id", "profiles.id")
          .to_a
          .size
          .should eq 2

        expect_raises DB::Error, "more than one row" do
          Profile.find.rel("users").left_join("users", "users.profile_id", "profiles.id").to_o
        end

        expect_raises DB::Error, "more than one row" do
          Profile.find.rel("users").left_join("users", "users.profile_id", "profiles.id").to_o!
        end
      end

      it %(should raise DB::NoResultsError: "no results") do
        expect_raises DB::NoResultsError, "no results" do
          Profile.find(42).rel("users").left_join("users", "users.profile_id", "profiles.id").to_o!
        end
      end

      it "should not raise DB::NoResultsError" do
        Profile
          .find(42)
          .rel("users")
          .left_join("users", "users.profile_id", "profiles.id")
          .to_o
          .should eq nil

        profiles = Profile.find(42).rel("users").left_join("users", "users.profile_id", "profiles.id").to_a
        profiles.should be_a Array(Profile::Schema)
        profiles.size.should eq 0
      end

      it "should prevent to provide an unsupported depth" do
        ex = expect_raises DBX::Error do
          Profile.find.rel("users.profile.users", :u)
        end

        message = ex.message.not_nil!
        message.should contain %(Relation path to long: "users.profile.users")
        message.should contain "cannot exceed 2 levels (max is \"users.profile\")"

        # --

        ex = expect_raises DBX::Error do
          Profile
            .find
            .rel("users")
            .rel("users.profile", :p)
            .rel("users.profile.users", :u)
            .join { "LEFT JOIN users on users.profile_id = profiles.id" }
            .join { "LEFT JOIN profiles as p ON p.id = users.profile_id" }
            .join { "LEFT JOIN users as u on u.profile_id = p.id" }
        end

        message = ex.message.not_nil!
        message.should contain %(Relation path to long: "users.profile.users")
        message.should contain "cannot exceed 2 levels (max is \"users.profile\")"
      end
    end
  end
{% end %}
