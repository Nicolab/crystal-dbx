# CRUD

<abbr title="Create Read Update Delete">CRUD</abbr> examples with the query builder (and executor),
see [ORM: CRUD](/guide/orm/crud.md) for the same using the DBX ORM.

> Note: With the ORM, the queries are simpler and more productive.

This doc assumes that you have initialized DBX, for example like this:

```crystal
require "dbx"
require "dbx/adapter/pg" # or require "dbx/adapter/sqlite"
require "dbx/query_builder"

DB_CONN = DBX.open("app", "postgres://...", strict: true)
DB_ADAPTER = DBX::Adapter::PostgreSQL.new(DB_CONN)

def new_query
  DBX::Query.new(DB_ADAPTER)
end
```

## Create

Simple insert:

```crystal
er = new_query.insert(:users, {username: "foo", email: "foo@example.org"}).exec!
puts er.rows_affected
```

Insert returning the new record:

```crystal
user = new_query
  .insert(:users, {username: "foo", email: "foo@example.org"})
  .returning
  .to_o({id: Int32, username: String, email: String})

if user
  pp user
end

# raises when no records found
user = new_query
  .insert(:users, {username: "foo", email: "foo@example.org"})
  .returning
  .to_o!({id: Int32, username: String, email: String})

pp user
```

> Note: [to_o!](https://nicolab.github.io/crystal-dbx/DBX/Query.html#to_o!(astypes)-instance-method) is an alias of [query_one!](https://nicolab.github.io/crystal-dbx/DBX/Query.html#query_one!(astypes)-instance-method), see [querying](/guide/querying.md) for more details.

Or `create!` method (helper), insert one, returning the new record:

```crystal
user = new_query.table(:users).create!(
  {username: "foo", email: "foo@example.org"},
  as: {id: Int32, username: String, email: String}
)

pp user
```

## Read

Find one:

```crystal
user = new_query
  .find(:users, :id, 42)
  .to_o({id: String, username: String, email: String})

if user
  puts user.email
end

# raises when no records found
user = new_query
  .find(:users, :id, 42)
  .to_o!({id: String, username: String, email: String})

puts user.email
```

another example:

```crystal
user = new_query
  .find(:users)
  .where(:job, "dev")
  .limit(1)
  .to_o({id: String, username: String, email: String})

if user
  puts user.email
end

# raises when no records found
user = new_query
  .find(:users)
  .where(:job, "dev")
  .limit(1)
  .to_o!({id: String, username: String, email: String})

puts user.email
```

Find all:

```crystal
users = new_query
  .find(:users)
  .to_a({id: String, username: String, email: String})
```

Find and get a [scalar](https://nicolab.github.io/crystal-dbx/DBX/Query.html#scalar-instance-method) value:

```crystal
id = new_query
  .find(:users)
  .select(:id)
  .where(:username, "foo")
  .scalar!
  .as(Int64)
```

With [count](https://nicolab.github.io/crystal-dbx/DBX/QueryBuilder.html#count(field:FieldType,name=nil):QueryBuilder-instance-method):

```crystal
total_users = new_query
  .find(:users)
  .count
  .scalar!
  .as(Int64)
```

## Update

Update one:

```crystal
er = new_query
  .table(:users)
  .update(:id, 42, {username: "bar", email: "bar@example.org"})
  .exec

puts er.rows_affected if er

# raises when no records found
er = new_query
  .table(:users)
  .update(:id, 42, {username: "bar", email: "bar@example.org"})
  .exec!

puts er.rows_affected
```

Update all:

```crystal
er = new_query
  .update(:users, {job: "dev", bio: "Happy!"})
  .exec

puts er.rows_affected if er

# raises when no records found
er = new_query
  .update(:users, {job: "dev", bio: "Happy!"})
  .exec!

puts er.rows_affected
```

With `pg` (PostgreSQL) adapter, it is possible to get the updated rows:

```crystal
updated_users = new_query
  .update(:users, {job: "dev", bio: "Happy!"})
  .returning(:id, :job, :bio)
  .to_a({id: Int64, job: String, bio: String})

pp updated_users
```

> Note: the `returning` support, will also be implemented in the SQLite adapter.

## Delete

Delete one:

```crystal
er = new_query.table(:users).delete(:id, 42).exec
puts er.rows_affected if er

# raises when no records found
er = new_query.table(:users).delete(:id, 42).exec!
puts er.rows_affected
```

Delete all:

```crystal
er = new_query.delete(:users).exec
puts er.rows_affected if er

# raises when no records found
er = new_query.delete(:users).exec!
puts er.rows_affected
```

With `pg` (PostgreSQL) adapter, it is possible to get the deleted rows:

```crystal
deleted_users = new_query
  .delete(:users)
  .returning(:id, :job, :bio)
  .to_a({id: Int64, job: String, bio: String})

pp deleted_users
```

> Note: the `returning` support, will also be implemented in the SQLite adapter.

## Summary

We have explored some examples of CRUD, to go further see also:

* [Querying](/guide/querying.md)
* [ORM: CRUD](/guide/orm/crud.md)
* [Troubleshooting](/guide/troubleshooting.md)