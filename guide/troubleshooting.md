# Troubleshooting

## Pitfalls

The goal of DBX is to bring a practical abstraction to crystal-db and its drivers.
As a result, DBX leaves a lot of freedom to implement models and queries.
This can lead to errors.
For example at each end of query you have to choose the right return of execution
(`to_o` / `to_o!` to force the return of a single resource,
`to_a` to get an array of one or more resources).
This requires some knowledge of _SQL_ and [crystal-db](https://crystal-lang.github.io/crystal-db/api/latest/DB/QueryMethods.html).

Great super power, great responsibility!

## Last insert ID

When registering with the `insert.exec` method,
depending on the SQL drivers (PostgreSQL or SQLite) the behavior
to get the registration ID is not identical
(behavior inherited from crystal-db and its SQL drivers).

* With SQLite driver `last_insert_id` (`DB::ExecResult`) returns the ID of the new record.
* With PostgreSQL driver this does not work. But it is possible to use the PostgreSQL-specific
`RETURNING id` statement and execute the query with `query` or `scalar`.

To help with this, the DBX query builder has the `returning` method
which accepts one or more fields (`*` (wildcard) for all SQL fields).

Also the `create!` method handles all this for you.
This method is accessible via `DBX::Query` and the models.