# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "../spec_helper"
require "../../src/adapter/pg"

# PGQueryBuilder is relevant here because it uses an incremental placeholder.
# This makes it possible to check the correspondence with the order of the arguments.
BUILDER       = DBX::Adapter::PGQueryBuilder.new
QUERIES_COUNT = Atomic.new(0)

def count_query(count = true)
  QUERIES_COUNT.add(1) if count
  QUERIES_COUNT.get
end
