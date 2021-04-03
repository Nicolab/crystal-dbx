# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "mg"
require "./*"

MIG = MG::Migration.new db_open

# Migrates to the latest version
# MIG.migrate

class User < DBX::ORM::Model
  # For generic tests adapters
  {% if ADAPTER_NAME == :pg %}adapter :pg{% end %}
  {% if ADAPTER_NAME == :sqlite %}adapter :sqlite{% end %}

  table :users
  connection "app"

  # DB table schema
  class Schema < DBX::ORM::Schema # (User)
    field id : Int64?
    field username : String

    # relation has_one
    field profile_id : Int64?

    # has one Profil
    relation profile : Profile
  end
end

class Profile < DBX::ORM::Model
  # For generic tests adapters
  {% if ADAPTER_NAME == :pg %}adapter :pg{% end %}
  {% if ADAPTER_NAME == :sqlite %}adapter :sqlite{% end %}

  table :profiles
  connection "app"

  # DB table schema
  class Schema < DBX::ORM::Schema # (Profile)
    field id : Int64?
    field name : String

    # has_many User
    relation users : Array(User)
  end
end

class Tag < DBX::ORM::Model
  # For generic tests adapters
  {% if ADAPTER_NAME == :pg %}adapter :pg{% end %}
  {% if ADAPTER_NAME == :sqlite %}adapter :sqlite{% end %}

  table :tags
  connection "app"

  # DB table schema
  class Schema < DBX::ORM::Schema # (Profile)
    field id : Int64?
    field name : String
    field user_id : Int64? = nil
    field profile_id : Int64? = nil

    # has_many User
    relation users : Array(User)

    # has_many Profil
    relation profiles : Array(Profile)
  end
end
