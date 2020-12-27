# Querying

DBX allows several ways to make queries, from low level (crystal-db),
to query builder (query executor) and ORM (model query).

DBX provides a query builder that can be used directly (example: `query.find(:users).where(:username, "foo")`)
or through models (example: `User.find.where(:username, "foo")`).

## Crystal DB query

```crystal
require "dbx"
require "pg" # <= Replaces by your database driver

# Connection URI / DSL https://www.postgresql.org/docs/current/libpq-connect.html#h5o-9
db = DBX.open("app", "postgres://...", true)

pp DBX.db?("app") ? "connected" : "not connected"

users = db.query_all(
  "select username, email from users",
  as: {name: String, email: String}
)

pp users

# Closes all connections of this DB entry point and remove it.
DBX.destroy("app")
```

> See [Crystal DB API: QueryMethods](https://crystal-lang.github.io/crystal-db/api/latest/DB/QueryMethods.html)

Just for example with a simple Crystal DB model:

```crystal
class User
  include JSON::Serializable
  include DB::Serializable
  include DB::Serializable::NonStrict

  property lang : String

  @[JSON::Field(key: "firstName")]
  property first_name : String?
end

db = DBX.db("app")

user = User.from_rs(db.query("SELECT id, lang, first_name FROM users"))
pp user.to_json

user = User.from_json "{\"lang\":\"fr\",\"firstName\":\"Nico\"}"
pp user
```

For a more advanced model system, see [ORM: Model](/guide/orm/model.md).

## Query builder

To build queries only, then get the SQL string and its array of arguments.

```crystal
require "dbx"
require "dbx/adapter/pg" # or require "dbx/adapter/sqlite"
require "dbx/query_builder"

builder = DBX::QueryBuilder.new
sql, args = builder.table(:users).insert({username: "foo", email: "foo@example.org"}).build

pp sql
pp args

# One
sql, args = builder.find(:users).where(:username, "foo").limit(1).build

pp sql
pp args

# All
sql, args = builder.find(:users).build

pp sql
pp args
```

> See [API: QueryBuilder](https://nicolab.github.io/crystal-dbx/DBX/QueryBuilder.html)

### Query executor

To build and execute the queries.

Bootstrap:

```crystal
require "dbx"
require "dbx/adapter/pg" # or require "dbx/adapter/sqlite"
require "dbx/query_builder"

DB_CONN = DBX.open("app", "postgres://...", strict: true)
DB_ADAPTER = DBX::Adapter::PostgreSQL.new(DB_CONN)

def new_query
  DBX::QueryExecutor.new(DB_ADAPTER)
end
```

Usage:

```crystal
er = new_query.table(:users).insert({username: "foo", email: "foo@example.org"}).exec!
puts er.rows_affected

# Find one
user = new_query.find(:users).where(:username, "foo").limit(1).to_o!
pp user

# Find all
users = new_query.find(:users).to_a
pp users
```

> See [API: QueryExecutor](https://nicolab.github.io/crystal-dbx/DBX/QueryExecutor.html)

### ORM - Model query

To build and execute the queries through a model.

Bootstrap:

```crystal
require "dbx"
require "dbx/adapter/pg" # or require "dbx/adapter/sqlite"
require "dbx/orm"

DBX.open("app", "postgres://...", strict: true)

class User < DBX::ORM::Model
  adapter :pg

  # table :users # <= automatically resolved from class name
  # db_entry "server2" # <= default is "app", but you can use another DB entry point.

  # DB table schema
  class Schema
    include DB::Serializable
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    property id : Int64?
    property username : String
    property email : String
  end

  # Custom (optional)
  class ModelQuery < DBX::ORM::ModelQuery(Test)
    def select_all
      self.select({:id, :username, :email})
    end
  end
end
```

Usage:

```crystal
user = User.create!({username: "foo", email: "foo@example.org"})
pp user

# Find one
user = User.find.where(:username, "foo").limit(1).to_o!
pp user

# Find all
users = User.find.to_a
pp users
```

## To keep in mind

Remember:

💡 Drivers and [crystal-db](https://crystal-lang.github.io/crystal-db/api/latest/index.html) are the common modules that ultimately interact with specific databases.

💡 DBX adapters are the classes that link DBX to the databases drivers (and crystal-db).

> `require "dbx/adapter/pg"` for PostgreSQL.
> `require "dbx/adapter/sqlite"` for SQLite.

💡 `dbx/query_builder` is the module that provides [DBX::QueryBuilder](https://nicolab.github.io/crystal-dbx/DBX/QueryBuilder.html) and [DBX::QueryExecutor](https://nicolab.github.io/crystal-dbx/DBX/QueryExecutor.html).

> `DBX::QueryBuilder` only takes care of building the query intended to be executed to the database.
>
> `DBX::QueryExecutor` builds the query with `DBX::QueryBuilder` and executes it to the database.

💡 [to_o](https://nicolab.github.io/crystal-dbx/DBX/QueryExecutor.html#to_o(astypes)-instance-method) is the same as [query_one](https://nicolab.github.io/crystal-dbx/DBX/QueryExecutor.html#query_one(astypes)-instance-method).

> Mnemonic: `to_o` (`query_one`) - to one, to object.
> Performs the query (`#query_one`) and returns the data (one object).
> Returns [DB::ResultSet](https://crystal-lang.github.io/crystal-db/api/latest/DB/ResultSet.html), the response of a query performed on a [DB::Database](https://crystal-lang.github.io/crystal-db/api/latest/DB/Database.html).

💡 [to_a](https://nicolab.github.io/crystal-dbx/DBX/QueryExecutor.html#to_a(astypes)-instance-method) is the same as [query_all](https://nicolab.github.io/crystal-dbx/DBX/QueryExecutor.html#query_all(astypes)-instance-method).

> Mnemonic: `to_a` (`query_all`) - to all, to array.
> Performs the query (`#query_all`) and returns the data (array of object).
> Returns [DB::ResultSet](https://crystal-lang.github.io/crystal-db/api/latest/DB/ResultSet.html), the response of a query performed on a [DB::Database](https://crystal-lang.github.io/crystal-db/api/latest/DB/Database.html).

💡 [scalar](https://nicolab.github.io/crystal-dbx/DBX/QueryExecutor.html#scalar-instance-method)

> Performs the [query](https://nicolab.github.io/crystal-dbx/DBX/QueryExecutor.html#query-instance-method) and returns a single scalar value.
> Returns a single scalar value (`String` or `Int32` or `Int64` or another Crystal type).

💡 [exec](https://nicolab.github.io/crystal-dbx/DBX/QueryExecutor.html#exec-instance-method)

> Execution that does not wait for data (scalar or object or array) from the database.
> Returns [DB::ExecResult](https://crystal-lang.github.io/crystal-db/api/latest/DB/ExecResult.html), result of a `#exec` statement.

## Summary

To go further, see:

* [Guide: ORM](/guide/orm/README.md)
* [API: ModelQuery](https://nicolab.github.io/crystal-dbx/DBX/ORM/ModelQuery.html)
* [API: QueryBuilder](https://nicolab.github.io/crystal-dbx/DBX/QueryBuilder.html)
* [API: QueryExecutor](https://nicolab.github.io/crystal-dbx/DBX/QueryExecutor.html)
* [Troubleshooting](/guide/troubleshooting.md)
