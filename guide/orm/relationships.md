# Relationships

> TODO: This doc should be completed with more details and examples.

Database tables are often related to one another. For example, a blog post may have many comments.

With DBX it is possible to add specific methods that will be accessible in the build of model queries (query builder of this model), example:

```crystal
class Post < DBX::ORM::Model
  adapter :pg

  # DB table schema
  class Schema
    include DB::Serializable
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    property id : Int64?
    property title : String
    property content : String
  end

  # Custom (optional)
  class ModelQuery < DBX::ORM::ModelQuery(Test)
    def with_comments
      self.join do
        "LEFT JOIN #{Comment.table_name} AS c ON c.#{Post.foreign_key_name} = #{Post.pk_name}"
      end

      # or self.left_join(Comment.table_name, ...)
    end
  end
end

# Find all posts with their comments
posts = Post.find.with_comments.to_a
```

> 👀 Doc in progress...

See also:

* [ORM: Model](/guide/orm/model.md)
* [ORM: CRUD](/guide/orm/crud.md)
* [Querying](/guide/querying.md)
* [API: ORM](https://nicolab.github.io/crystal-dbx/DBX/ORM.html)
