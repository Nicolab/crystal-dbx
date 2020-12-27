# ORM CRUD

<abbr title="Create Read Update Delete">CRUD</abbr> examples with the ORM,
see [Query builder: CRUD](/guide/crud.md) for the same using the DBX query builder.

This doc assumes that you have initialized a DBX model, for example like this:

```crystal
require "dbx"
require "dbx/adapter/pg" # or require "dbx/adapter/sqlite"
require "dbx/orm"

DB_CONN = DBX.open("app", "postgres://...", strict: true)
DB_ADAPTER = DBX::Adapter::PostgreSQL.new(DB_CONN)

class User < DBX::ORM::Model
  adapter :pg
  # table :users # <= automatically resolved

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
```

## Create

```crystal
user = User.create!({name: "foo", about: "Love Crystal lang", age: 38})
puts user.name
```

With returning insert:

```crystal
user = User
  .insert({name: "foo", about: "Love Crystal lang", age: 38})
  .returning
  .to_o

if user
  puts user.name
end


user = User
  .insert({name: "foo", about: "Love Crystal lang", age: 38})
  .returning
  .to_o! # raises when is not inserted
```

Only insert:

```crystal
er = User
  .insert({name: "foo", about: "Love Crystal lang", age: 38})
  .exec

if er
  puts er.rows_affected
end

er = User
  .insert({name: "foo", about: "Love Crystal lang", age: 38})
  .exec! # raises when is not inserted

puts er.rows_affected
```

## Read

Find one:

```crystal
user = User.find(42).to_o

if user
  puts user.name
end

user = User.find(42).to_o! # raises when no records found
```

Scalar (count):

```crystal
puts total_users if total_users = User.find.count(:id).scalar.as(Int64)

# raises when no records found
total_users = User.find.count(:id).scalar!.as(Int64)
puts total_users
```

Find all:

```crystal
users = User.find.where(:age, ">=", 21).to_a
pp users
```

## Update

Update one:

```crystal
er = User.update(42, {name: "bar"}).exec
puts er.rows_affected if er

# raises when no records found
er = User.update(42, {name: "bar"}).exec!
puts er.rows_affected
```

With returning update:

```crystal
user = User
  .update(42, {name: "foo", about: "Love Crystal lang", age: 38})
  .returning
  .to_o

if user
  puts user.name
end

user = User
  .update(42, {name: "foo", about: "Love Crystal lang", age: 38})
  .returning
  .to_o! # raises when is not inserted
```

Update all:

```crystal
er = User.update({name: "bar"}).exec
puts er.rows_affected if er

# raises when no records found
er = User.update({name: "bar"}).exec!
puts er.rows_affected
```

With returning update:

```crystal
users = User
  .update({name: "foo", about: "Love Crystal lang"})
  .returning
  .to_a

if users.size
  pp users
end
```

## Delete

Delete one:

```crystal
er = User.delete(42).exec
puts er.rows_affected if er

# raises when no records found
er = User.delete(42).exec!
puts er.rows_affected
```

With returning delete:

```crystal
user = User
  .delete(42)
  .returning
  .to_o

if user
  puts user.name
end

user = User
  .delete(42)
  .returning
  .to_o! # raises when is not inserted
```

Delete all:

```crystal
er = User.delete.where(:age, "<", 21).exec
puts er.rows_affected if er

# raises when no records found
er = User.delete.where(:age, "<", 21).exec!
puts er.rows_affected
```

With returning delete:

```crystal
users = User
  .delete
  .where(:age, "<", 21)
  .returning
  .to_a

if users.size
  pp users
end
```

## Summary

We have explored some examples of ORM CRUD, to go further see also:

* [Querying](/guide/querying.md)
* [Model](/guide/orm/model.md)
* [CRUD with query builder](/guide/crud.md)
* [Troubleshooting](/guide/troubleshooting.md)