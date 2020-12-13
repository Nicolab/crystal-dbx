# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

module DBX
  # Handy `QueryBuilder` scope used into `Block`.
  struct QueryBuilderScope
    alias FieldType = QueryBuilder::FieldType

    def initialize(@builder : QueryBuilder)
    end

    # Same as `QueryBuilder#add_arg`
    def arg(value) : String
      @builder.add_arg(value)
    end

    # Same as `QueryBuilder#quote`
    def q(field : FieldType, io : IO::Memory) : IO::Memory
      @builder.quote(field, io)
    end

    # Same as `QueryBuilder#quote`
    def q(field : FieldType) : String
      @builder.quote(field)
    end
  end
end
