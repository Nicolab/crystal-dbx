# DBX ORM Model

> TODO: This doc should be completed with more details.

Example:

```crystal
require "dbx"
require "dbx/adapter/pg" # or require "dbx/adapter/sqlite"
require "dbx/orm"

DBX.open("app", "postgres://...", strict: true)

class User < DBX::ORM::Model
  # :pg or :sqlite
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

    def with_posts
      self.join do
        "LEFT JOIN #{Post.table_name} AS p ON p.#{User.foreign_key_name} = #{User.pk_name}"
      end
    end
  end
end
```

Some explanations:

\- `User::Schema` is the table schema used by `crystal-db`.
`Schema` class can be passed to any querie handled by `crystal-db` (often via the `as` argument). This makes DBX models easily transportable.

\- `User::ModelQuery` allows to add customized and prepared statements to the `User` model.
This injects methods into the query builder of the current model, that can be used to build queries.

See also:

* [ORM: CRUD](/guide/orm/crud.md) (to see examples of queries with a model)
* [ORM: validations](/guide/orm/validations.md)
* [ORM: relationships](/guide/orm/relationships.md)
* [API: Model](https://nicolab.github.io/crystal-dbx/DBX/ORM/Model.html)
* [Querying](/guide/querying.md)