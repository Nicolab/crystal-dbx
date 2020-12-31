# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX::ORM
  # Base class for all models.
  #
  # Example, creation of a model for a table `users`:
  #
  # ```
  # class User < DBX::ORM::Model
  #   adapter :pg
  #
  #   class Schema
  #     include DB::Serializable
  #     include JSON::Serializable
  #     include JSON::Serializable::Unmapped
  #
  #     property id : Int64?
  #     property name : String
  #     property about : String
  #     property age : Int32
  #   end
  # end
  # ```
  #
  # Customize `ModelQuery` used by `User` model:
  #
  # ```
  # class User < DBX::ORM::Model
  #   # ...
  #
  #   class ModelQuery < DBX::ORM::ModelQuery(User)
  #     # By default `SELECT` value is `*`,
  #     # this method select all fields explicitly.
  #     def select_all
  #       self.select({:id, :name, :about, :age})
  #     end
  #   end
  # end
  # ```
  #
  # In the model example above, we have added a new method (`select_all`) to `ModelQuery',
  # which can be used in each query.
  #
  # ```
  # user = User.find(id).select_all.to_o
  # users = User.find.select_all.to_a
  # ```
  abstract class Model
    @@adapter : DBX::Adapter::Base?
    @@conn_name : String = "app"

    # Model error.
    class Error < DBX::Error; end

    # `Model` Schema.
    class Schema
      # Always returns this record's primary key value, even when the primary key
      # isn't named `pk`.
      @[DB::Field(ignore: true)]
      @[JSON::Field(ignore: true)]
      def pk!
        self.pk.not_nil!
      end

      # Same as `pk` but may return `nil` when the record hasn't been saved
      # instead of raising.
      @[DB::Field(ignore: true)]
      @[JSON::Field(ignore: true)]
      def pk
        self.id
      end
    end

    # Defines adapter class to use with this model.
    # *name* MUST be `pg` or `SQLite` (case-insensitive) as a `Symbol` or `String`.
    #
    # PostgreSQL:
    #
    # ```
    # adapter :pg
    # # or
    # adapter "pg"
    # ```
    #
    # SQLite:
    #
    # ```
    # adapter :SQLite
    # # or
    # adapter :sqlite
    # # or
    # adapter "SQLite"
    # # or
    # adapter "sqlite"
    # ```
    private macro adapter(name)
      {% name = name.id.downcase %}
      {% if name == "pg" %}
        DBX::Adapter.inject_pg
      {% end %}

      {% if name == "sqlite" %}
        DBX::Adapter.inject_sqlite
      {% end %}
    end

    # By default table name is resolved by adding `s` (lazy plurial) to the model name.
    # It's possible to define another table name with a `Symbol` or a `String`.
    #
    # ```
    # # Symbol
    # table :my_table
    #
    # # or String
    # table "my_table"
    # ```
    private macro table(name)
      @@table_name = "{{name.id}}"
    end

    # Define a DB connection name with a `Symbol` or a `String`.
    # By default is `app`.
    #
    # ```
    # # Symbol
    # connection :connection_name
    #
    # # or String
    # connection "connection_name"
    # ```
    #
    # See `.db` and `.connection`.
    private macro connection(name)
      @@conn_name = "{{name.id}}"
    end

    macro inherited
      # table name
      class_property table_name : String = {{ @type.name.split("::").last.underscore + "s" }}

      # Primary key
      class_getter pk_name : String = "id"

      # Type of primary key
      class_getter pk_type = Int64

      # Sets custom model foreign key name.
      #
      # ```
      # class User < DBX::ORM::ModelQuery
      #   foreign_key_name :client_id
      # end
      # ```
      def self.foreign_key_name(value : String | Symbol)
        @@foreign_key_name = value.to_s
      end

      # Returns model foreign key name.
      def self.foreign_key_name
        return @@foreign_key_name unless @@foreign_key_name.nil?
        @@foreign_key_name = "#{self.table_name.to_s.rchop('s')}_id"
      end

      # `DBX::QueryExecutor` specific to `Model`.
      class ModelQuery < DBX::ORM::ModelQuery({{@type.name.id}})
      end

      # MUST be placed after ModelQuery class
      extend DBX::ORM::ModelMixin({{@type.name.id}}, ModelQuery)
    end

    # Adapter used by this `Model`
    protected def self.adapter_class : DBX::Adapter::Base.class
      raise NotImplementedError.new(
        "'#{self}' model MUST define '#{self}.adapter' method."
      )
    end

    # Adapter used by this `Model`.
    protected def self.adapter : DBX::Adapter::Base
      @@adapter ||= self.adapter_class.new(self.db)
    end

    # --------------------------------------------------------------------------

    # DB connection name used by this `Model` instance.
    def self.connection : String
      @@conn_name
    end

    # Returns DB connection name used by this `Model` instance.
    def self.db : DB::Database
      DBX.db(connection)
    end

    # Returns array of all non-abstract subclasses of *DBX::ORM::Model.
    #
    # ```
    # DBX::ORM::Model.models # => [Contact, Address, User]
    # ```
    def self.models
      {% begin %}
        {% models = @type.all_subclasses.select { |m| !m.abstract? } %}
        {% if !models.empty? %}
          [
            {% for model in models %}
              ::{{model.name}},
            {% end %}
          ]
        {% else %}
          [] of ::DBX::ORM::Model.class
        {% end %}
      {% end %}
    end
  end
end
