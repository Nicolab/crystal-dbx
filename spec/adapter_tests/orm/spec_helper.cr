# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "../../spec_helper"
require "../../../src/orm"

class Test2 < DBX::ORM::Model
  # For generic tests adapters
  {% if ADAPTER_NAME == :pg %}adapter :pg{% end %}
  {% if ADAPTER_NAME == :sqlite %}adapter :sqlite{% end %}

  table :tests
  connection "test2"

  # DB table schema
  class Schema
    include DB::Serializable
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    property id : Int64?
    property name : String
    property about : String
    property age : Int32
  end
end

class Test < DBX::ORM::Model
  # For generic tests adapters
  {% if ADAPTER_NAME == :pg %}adapter :pg{% end %}
  {% if ADAPTER_NAME == :sqlite %}adapter :sqlite{% end %}

  # table :tests # <= automatically resolved

  # DB table schema
  class Schema
    include DB::Serializable
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    property id : Int64?
    property name : String
    property about : String
    property age : Int32
  end

  class ModelQuery < DBX::ORM::ModelQuery(Test)
    def select_all
      self.select({:id, :name, :about, :age})
    end
  end
end

class TestPK < DBX::ORM::Model
  # For generic tests adapters
  {% if ADAPTER_NAME == :pg %}adapter :pg{% end %}
  {% if ADAPTER_NAME == :sqlite %}adapter :sqlite{% end %}

  table :tests

  class_getter pk_name : String = "uid"
  class_getter pk_type = String
  class_getter fk_name = "test_uid"

  # DB table schema
  class Schema
    include DB::Serializable
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    @[DB::Field(ignore: true)]
    @[JSON::Field(ignore: true)]
    def pk
      self.uid
    end

    property uid : String
    property name : String
    property about : String
    property age : Int32
  end
end
