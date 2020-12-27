# Install DBX

DBX is designed in a decoupled way to embed only the necessary features (multi-connections manager, query builder, query executor and ORM).

DBX uses the common [crystal-db](https://github.com/crystal-lang/crystal-db) API for Crystal. You will need to have a specific driver to access a database.

> SQLite, PostgreSQL, MySQL, Cassandra, ... See the list of the compatible drivers: https://github.com/crystal-lang/crystal-db

DBX connections manager supports the same drivers as [crystal-db](https://github.com/crystal-lang/crystal-db).

Concerning the query builder and the ORM, only adapters for PostgreSQL and SQLite are (officially) supported and maintained. However, creating an adapter for MySQL or Cassandra should not be complicated (take example on existing adapters).

▶️ To install DBX:

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  dbx:
    github: nicolab/crystal-dbx

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

## Summary

The next chapter explores the [connection and multi-connections](/guide/connection.md), an essential chapter to start with DBX.
