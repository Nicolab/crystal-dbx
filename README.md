# :sparkles: DBX

[![CI Status](https://github.com/Nicolab/crystal-dbx/workflows/CI/badge.svg?branch=master)](https://github.com/Nicolab/crystal-dbx/actions) [![GitHub release](https://img.shields.io/github/release/Nicolab/crystal-dbx.svg)](https://github.com/Nicolab/crystal-dbx/releases) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://nicolab.github.io/crystal-dbx/)

* `DBX` is a module for [Crystal lang](https://crystal-lang.org). `DBX` adds multi-connection support to the database and useful helpers.

* `DBX` is designed in a decoupled way to embed only the necessary functionalities (multi-connection manager, query builder and ORM).

* `DBX` uses the common [crystal-db](https://github.com/crystal-lang/crystal-db) API for Crystal. You will need to have a specific driver to access a database.

> SQLite, PostgreSQL, MySQL, Cassandra, ... See the list of the compatible drivers: https://github.com/crystal-lang/crystal-db
_Concerning the query builder and the ORM, adapters for PostgreSQL and SQLite are supported by DBX._

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  dbx:
    github: https://github.com/nicolab/crystal-dbx

  # Pick / uncomment your database
  # pg:
  #   github: will/crystal-pg
  #   # Add the last version, example: version: ~> 0.20.0

  # mysql:
  #   github: crystal-lang/crystal-mysql
  #   # Add the last version, example: version: 0.10.0

  # sqlite3:
  #   github: crystal-lang/crystal-sqlite3
  #   # Add the last version, example: version: 0.15.0
```

2. Run `shards install`

## Usage

Example with PostgreSQL:

```ruby
require "dbx"
require "pg" # <= Replaces by your database driver

# Connection URI / DSL https://www.postgresql.org/docs/current/libpq-connect.html#h5o-9
db = DBX.open("app", "postgres://...", true)

pp DBX.db?("app") ? "connected" : "not connected"

db.query "select id, created_at, email from users" do |rs|
  rs.each do
    id = rs.read(Int32)
    created_at = rs.read(Time)
    email = rs.read(String)
    puts "##{id}: #{email} #{created_at}"
  end
end

# Closes all connections of this DB entry point and remove it.
DBX.destroy("app")
```

Model example:

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

See also:

* :rocket: `DBX::ORM` for a more advanced model system and query builder.
* 📘 [API doc](https://nicolab.github.io/crystal-dbx/)
* :bookmark_tabs: [Spec](https://github.com/Nicolab/crystal-dbx/tree/master/spec)

## Troubleshooting

### Pitfalls

The goal of DBX is to bring a practical abstraction to crystal-db.
As a result, DBX leaves a lot of freedom to implement models and queries.
This can lead to errors.
For example at each end of query you have to choose the right executor
(`to_o` / `to_o!` to force the return of a single resource,
`to_a` / `to_a!` to get an array of one or more resources, `exec` or `query`, ...).
This requires some knowledge of _SQL_ and [crystal-db](https://crystal-lang.github.io/crystal-db/api/latest/DB/QueryMethods.html).

Great super power, great responsibility!

### Last insert ID

When registering with the `insert.exec` method,
depending on the SQL drivers (PostgreSQL or SQLite) the behavior
to get the registration ID is not identical
(behavior inherited from crystal-db and its SQL drivers).

* With SQLite driver `last_insert_id` (`DB::ExecResult`) returns the ID of the new record.
* With PostgreSQL driver this does not work. But it is possible to use the PostgreSQL-specific
`RETURNING id` statement and execute the query with `query` or `scalar`.

To help with this, the DBX query builder has the `returning` method
which accepts one or more fields (`*` (wildcard) for all SQL fields).

Also the `create` method handles all this for you.
This method is accessible via `DBX::QueryExecutor` and the models.

## Contributing

1. Fork it (<https://github.com/Nicolab/crystal-dbx/fork>).
2. Create your feature branch (`git checkout -b my-new-feature`).
3. See [Development](#Development).
4. Commit your changes (`git commit -am 'Add some feature'`).
5. Push to the branch (`git push origin my-new-feature`).
6. Create a new Pull Request.

### Development

1. You only need Git, Docker and Docker-compose installed on your machine.
2. Clone this repo and run `./scripts/prepare`.
3. Run first `docker-compose up`,
  3.1. then enter to container `docker-compose exec test_pg bash` (or `test_sqlite` service),
  3.2. into the container `just dev-spec`.
4. Check the project before committing or pushing, from the host: `./scripts/check`

It's just Docker and docker-compose, you can directly type all the commands Docker and docker-compose.

✨ Example:

_Terminal 1_

```sh
# Start the dev stack
docker-compose up
```

_Terminal 2_

```sh
# enter in the test_pg container
docker-compose exec test_pg bash

# then in the test_pg container
crystal run ./src/app.cr

# or with a recipe (helper)
just dev-spec # <= auto reload when the code change

# recipe list
just --list
```

Also, quickly:

* `docker-compose run --rm test_pg bash -c "crystal spec"`
* or `docker-compose run --rm test_pg bash -c "just dev-spec"`
* when you are done: `docker-compose down --remove-orphans`

## LICENSE

[MIT](https://github.com/Nicolab/crystal-dbx/blob/master/LICENSE) (c) 2020, Nicolas Talle.

## Author

- [Nicolas Talle (@Nicolab)](https://github.com/Nicolab) - Creator and maintainer
- This project is useful to you? [Sponsor the developer](https://github.com/sponsors/Nicolab)
