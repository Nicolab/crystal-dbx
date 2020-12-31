# Connection

DBX supports multi-connections to the database. It is just a light [crystal-db](https://github.com/crystal-lang/crystal-db) overlay.

```crystal
require "dbx"
require "pg" # <= PostgreSQL driver
require "sqlite3" # <= SQLite driver

# Create 4 DB connection pool (3 PostgreSQL and 1 SQLite)
DBX.open("app", "postgres://...", strict: true)
DBX.open("reader", "postgres://...", strict: true)
DBX.open("writer", "postgres://...", strict: true)
DBX.open("local", "sqlite3://./data.db", strict: true)

# Connection: app (using PostgreSQL)
DBX.db("app")

# Connection: local (using SQLite)
DBX.db("local")

# Connection: reader (using PostgreSQL)
DBX.db("reader")

# Connection: writer (using PostgreSQL)
DBX.db("writer")
```

> See [API: DBX connection](https://nicolab.github.io/crystal-dbx/DBX.html)

You can use each DBX connection as you do with [crystal-db](https://crystal-lang.github.io/crystal-db/api/latest/DB/QueryMethods.html)
(example: `DBX.db("app").query "select id, created_at, email from users"`).

## Summary

The next chapter explores [database querying](/guide/querying.md), an essential chapter to take advantage of DBX's powerful querying capabilities.
