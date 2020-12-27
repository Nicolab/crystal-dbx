# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX::ORM
  # Generic `ModelQuery` class.
  # > Automatically injected into the models.
  #
  # If you want to customize the queries of a model, you can define
  # you own `ModelQuery` into this model.
  #
  # ```
  # class User < DBX::ORM::Model
  #   # ...
  #
  #   class ModelQuery < DBX::ORM::ModelQuery(User)
  #     # By default `SELECT` value is `*`,
  #     # this method select all fields explicitly.
  #     def select_all
  #       self.select({:id, :name, :about, :age})
  #     end
  #   end
  # end
  # ```
  #
  # In the model example above, we have added a new method (`select_all`) to `ModelQuery',
  # which can be used in each query.
  #
  # ```
  # user = User.find(id).select_all.to_o
  # users = User.find.select_all.to_a
  # ```
  class ModelQuery(Model) < DBX::QueryExecutor
    # Executes current query using current `Model::Schema`.
    def query_one
      query_one(as: Model::Schema)
    end

    # Executes current query using current `Model::Schema`.
    def query_one!
      query_one!(as: Model::Schema)
    end

    # Executes current query using current `Model::Schema`.
    def query_all
      query_all(as: Model::Schema)
    end

    # Creates a new record and returns.
    #
    # ```
    # test = Test.create!(data)
    # puts test.id
    # ```
    def create!(data, returning : DBX::QueryBuilder::OneOrMoreFieldsType = "*")
      create!(
        data,
        as: Model::Schema,
        returning: returning,
        pk_name: Model.pk_name,
        pk_type: Model.pk_type
      )
    end

    # Shortcut, same as `query_one!`.
    def to_o!
      query_one!(as: Model::Schema)
    end

    # Shortcut, same as `query_one`.
    def to_o
      query_one(as: Model::Schema)
    end

    # Shortcut, same as `query_one!(types)`.
    def to_o!(as types)
      query_one!(types)
    end

    # Shortcut, same as `query_one(types)`.
    def to_o(as types)
      query_one(types)
    end

    # Shortcut, same as `query_all`.
    def to_a
      query_all(as: Model::Schema)
    end

    # Shortcut, same as `query_all(types)`.
    def to_a(as types)
      query_all(types)
    end
  end
end
