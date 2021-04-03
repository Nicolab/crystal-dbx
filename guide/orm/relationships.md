# Relationships

> TODO: This doc should be completed with more details and examples.

Database tables are often related to one another. For example, a blog post may have many comments.

With DBX it is possible to add specific methods that will be accessible in the build of model queries (query builder of this model), example:

```crystal
class Post < DBX::ORM::Model
  adapter :pg

  # DB table schema
  class Schema
    field id : Int64?
    field title : String
    field content : String

    relation comments : Array(Comment)
  end

  # Custom (optional)
  class ModelQuery < DBX::ORM::ModelQuery
    def with_comments
      self.rel("comments").left_join("comments", "comments.post_id", "posts.id")
      # Or self.join { "LEFT JOIN comments ON comments.post_id = posts.id" }
      # Or agnostic of changes:
      # .left_join("#{Comment.table_name} AS c", "c.#{Comment}.#{Post.fk_name}", "#{Post.table_name}.#{Post.pk_name}")
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
