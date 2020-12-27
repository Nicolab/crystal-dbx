# This file is part of "DBX".
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-dbx
# ------------------------------------------------------------------------------

require "db"

# DBX is a helper to handle multi DBs using the compatible drivers
# with the common `crystal-db` module.
#
# Example with PostgreSQL:
#
# ```
# # Connection URI / DSL https://www.postgresql.org/docs/current/libpq-connect.html#h5o-9
# db = DBX.open("app", "postgres://...", true)
#
# pp DBX.db?("app") ? "defined" : "not defined"
#
# db.query "select id, created_at, email from users" do |rs|
#   rs.each do
#     id = rs.read(Int32)
#     created_at = rs.read(Time)
#     email = rs.read(String)
#     puts "##{id}: #{email} #{created_at}"
#   end
# end
#
# # Closes all connections of this DB entry point and remove this DB entry point.
# DBX.destroy("app")
# ```
#
# Model:
#
# ```
# class User
#   include JSON::Serializable
#   include DB::Serializable
#   include DB::Serializable::NonStrict
#
#   property lang : String
#
#   @[JSON::Field(key: "firstName")]
#   property first_name : String?
# end
#
# db = DBX.open "app", App.cfg.db_uri
#
# user = User.from_rs(db.query("SELECT id, lang, first_name FROM users"))
# pp user.to_json
#
# user = User.from_json "{\"lang\":\"fr\",\"firstName\":\"Nico\"}"
# pp user
# ```
#
# See also `DBX::ORM` for a more advanced model system and query builder.
#
# Resources:
# - https://crystal-lang.github.io/crystal-db/api/index.html
# - https://github.com/Nicolab/crystal-dbx/tree/master/guide
module DBX
  alias DBHashType = Hash(String, DB::Database)

  # Raised when an error occurred, related with `DB` or `DBX`.
  class Error < DB::Error; end

  # Raised when a method is not supported.
  #
  # This can be used either to stub out method bodies,
  # or when the method is not supported on the current adapter.
  class NotSupportedError < NotImplementedError; end

  # Registered DB entry points
  @@dbs = DBHashType.new

  # Returns all `DB::Database` instances.
  def self.dbs : DBHashType
    @@dbs
  end

  # Checks that a DB entry point exists.
  def self.db?(name : String) : Bool
    @@dbs.has_key?(name)
  end

  # Uses a given DB entry point.
  def self.db(name : String) : DB::Database
    @@dbs[name]
  end

  # Same as `.open`.
  def self.db(name : String, uri : String, strict = false) : DB::Database
    self.open(name, uri, strict)
  end

  # Ensures only once DB entry point by *name* is open.
  # If the DB entry point *name* is already initialized, it is returned.
  # Raises an error if *strict* is *true* and the DB entry point *name* is
  # already opened.
  def self.open(name : String, uri : String, strict = false) : DB::Database
    # if already initialized
    if @@dbs.has_key?(name)
      return @@dbs[name] unless strict
      raise "'#{name}' DB entry point is already opened"
    end

    @@dbs[name] = DB.open(uri)
  end

  # Closes all connections of the DB entry point *name*
  # and remove the *name* DB entry point.
  def self.destroy(name : String)
    if @@dbs.has_key?(name)
      begin
        self.db(name).close
      rescue e : Exception
        puts "\n\u{1F47B} DBX.destroy: error caught when closing:"
        pp e
      end
      @@dbs.delete name
    end
  end

  # Destroy all DB entry points and and their connections.
  def self.destroy : Tuple(Int32, Int32)
    size = @@dbs.size
    @@dbs.each_key { |name| self.destroy(name) }
    {@@dbs.size, size}
  end

  # --------------------------------------------------------------------------
  # Pool
  # --------------------------------------------------------------------------

  # Pool stats
  # https://crystal-lang.github.io/crystal-db/api/latest/DB/Pool.html
  def self.pool_stats(name : String) : DB::Pool::Stats?
    self.db(name).pool.stats if self.db? name
  end

  # Gets the number of the connections opened in the pool of *name*.
  def self.pool_open_connections(name : String) : Int32
    pool_stats = self.pool_stats name
    return 0 unless pool_stats
    pool_stats.open_connections
  end

  # This macro allows injecting code to be run before and after the execution
  # of the request. It should return the yielded value. It must be called with 1
  # block argument that will be used to pass the `args : Enumerable`.
  # This macro should be called at the top level, not from a method.
  #
  # > Be careful of the performance penalty that each hook may cause,
  #   be aware that your code will be executed at each query and exec.
  #
  # ```
  # DBX.around_query_or_exec do |args|
  #   puts "before"
  #   res = yield
  #   puts "after"
  #
  #   puts res.class
  #   puts "exec" if res.is_a?(DB::ExecResult)
  #   puts "query" if res.is_a?(DB::ResultSet)
  #
  #   puts "with args:"
  #   pp args
  #
  #   res
  # end
  # ```
  #
  # Example to measure query execution time:
  #
  # ```
  # DBX.around_query_or_exec do |args|
  #   start = Time.monotonic
  #   res = yield
  #   elapsed_time = Time.monotonic - start
  #
  #   puts "Query execution time: #{elapsed_time}"
  #   res
  # end
  # ```
  macro around_query_or_exec(&block)
    class ::DB::Statement
      def_around_query_or_exec do |args|
        {{block.body}}
      end
    end
  end

  at_exit {
    self.destroy
  }
end
