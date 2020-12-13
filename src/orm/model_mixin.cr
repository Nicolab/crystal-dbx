# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX::ORM
  # Mixin for `Model` class.
  # > Automatically injected into the models.
  module ModelMixin(Model, ModelQuery)
    # Creates a new `ModelQuery` instance.
    def query : ModelQuery
      ModelQuery.new(self.adapter).table(self.table_name)
    end

    # Find one or more resources.
    def find : ModelQuery
      query.find
    end

    # Find one resource by its primary key.
    def find(pk_value) : ModelQuery
      query.find(Model.pk_name, pk_value)
    end

    # Inserts a new resource.
    def insert(data : Hash | NamedTuple) : ModelQuery
      query.insert(data)
    end

    # Creates a new resource and returns.
    def create(
      data : Hash | NamedTuple,
      returning : DBX::QueryBuilder::OneOrMoreFieldsType = "*"
    ) : Model::Schema
      query.create(data, returning: returning)
    end

    # Update one or more resources.
    def update(data : Hash | NamedTuple) : ModelQuery
      query.update(data)
    end

    # Updates one resource by its primary key.
    def update(pk_value, data : Hash | NamedTuple) : ModelQuery
      query.update(Model.pk_name, pk_value, data)
    end

    # Deletes one or more resources.
    def delete : ModelQuery
      query.delete
    end

    # Deletes one resource by its primary key.
    def delete(pk_value) : ModelQuery
      query.delete(Model.pk_name, pk_value)
    end
  end
end
