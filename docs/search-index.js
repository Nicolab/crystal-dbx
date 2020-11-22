crystal_doc_search_index_callback({"repository_name":"dbx","body":"# DBX\n\n[![CI Status](https://github.com/Nicolab/crystal-dbx/workflows/CI/badge.svg?branch=master)](https://github.com/Nicolab/crystal-dbx/actions) [![GitHub release](https://img.shields.io/github/release/Nicolab/crystal-dbx.svg)](https://github.com/Nicolab/crystal-dbx/releases) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://nicolab.github.io/crystal-dbx/)\n\n`DBX` is a very small module (no overhead) for [Crystal lang](https://crystal-lang.org). `DBX` adds multi-connection support to the database and useful helpers.\n\n`DBX` uses the common [crystal-db](https://github.com/crystal-lang/crystal-db) API for Crystal. You will need to have a specific driver to access a database.\n\nSQLite, PostgreSQL, MySQL, Cassandra, ... See the list of the compatible drivers: https://github.com/crystal-lang/crystal-db\n\n## Installation\n\n1. Add the dependency to your `shard.yml`:\n\n```yaml\ndependencies:\n  dbx:\n    github: https://github.com/nicolab/crystal-dbx\n\n  # Pick / uncomment your database\n  # pg:\n  #   github: will/crystal-pg\n  #   # Add the last version, example: version: ~> 0.20.0\n\n  # mysql:\n  #   github: crystal-lang/crystal-mysql\n  #   # Add the last version, example: version: 0.10.0\n\n  # sqlite3:\n  #   github: crystal-lang/crystal-sqlite3\n  #   # Add the last version, example: version: 0.15.0\n```\n\n2. Run `shards install`\n\n## Usage\n\nExample with PostgreSQL:\n\n```ruby\nrequire \"dbx\"\nrequire \"pg\" # <= Replaces by your database driver\n\n# Connection URI / DSL https://www.postgresql.org/docs/current/libpq-connect.html#h5o-9\ndb = DBX.open(\"app\", \"postgres://...\", true)\n\npp DBX.db?(\"app\") ? \"connected\" : \"not connected\"\n\ndb.query \"select id, created_at, email from users\" do |rs|\n  rs.each do\n    id = rs.read(Int32)\n    created_at = rs.read(Time)\n    email = rs.read(String)\n    puts \"##{id}: #{email} #{created_at}\"\n  end\nend\n\n# Closes all connections of this DB entry point and remove it.\nDBX.destroy(\"app\")\n```\n\nModel example:\n\n```crystal\nclass User\n  include JSON::Serializable\n  include DB::Serializable\n  include DB::Serializable::NonStrict\n\n  property lang : String\n\n  @[JSON::Field(key: \"firstName\")]\n  property first_name : String?\nend\n\ndb = DBX.db(\"app\")\n\nuser = User.from_rs(db.query(\"SELECT id, lang, first_name FROM users\"))\npp user.to_json\n\nuser = User.from_json \"{\\\"lang\\\":\\\"fr\\\",\\\"firstName\\\":\\\"Nico\\\"}\"\npp user\n```\n\n## Contributing\n\n1. Fork it (<https://github.com/Nicolab/crystal-dbx/fork>).\n2. Create your feature branch (`git checkout -b my-new-feature`).\n3. See [Development](#Development).\n4. Commit your changes (`git commit -am 'Add some feature'`).\n5. Push to the branch (`git push origin my-new-feature`).\n6. Create a new Pull Request.\n\n### Development\n\n1. You only need Git, Docker and Docker-compose installed on your machine.\n2. Clone this repo and run `./scripts/prepare`.\n3. Run first `docker-compose up`, then `./scripts/just dev-spec`).\n4. Check the project before committing or pushing: `./scripts/check`\n\nIt's just Docker and docker-compose, you can directly type the commands Docker and docker-compose if you prefer.\n\n✨ Example:\n\n_Terminal 1_\n\n```sh\n# Start the dev stack\ndocker-compose up\n```\n\n_Terminal 2_\n\n```sh\n# enter in the app container\ndocker-compose exec app bash\n\n# then in the app container\ncrystal run ./src/app.cr\n\n# or with a recipe (helper)\njust dev-spec # <= auto reload when the code change\n\n# recipe list\njust --list\n```\n\n## LICENSE\n\n[MIT](https://github.com/Nicolab/crystal-dbx/blob/master/LICENSE) (c) 2020, Nicolas Talle.\n\n## Author\n\n- [Nicolas Talle (@Nicolab)](https://github.com/Nicolab) - Creator and maintainer\n- This project is useful to you? [Sponsor the developer](https://github.com/sponsors/Nicolab)\n","program":{"html_id":"dbx/toplevel","path":"toplevel.html","kind":"module","full_name":"Top Level Namespace","name":"Top Level Namespace","abstract":false,"superclass":null,"ancestors":[],"locations":[],"repository_name":"dbx","program":true,"enum":false,"alias":false,"aliased":"","const":false,"constants":[],"included_modules":[],"extended_modules":[],"subclasses":[],"including_types":[],"namespace":null,"doc":null,"summary":null,"class_methods":[],"constructors":[],"instance_methods":[],"macros":[],"types":[{"html_id":"dbx/DBX","path":"DBX.html","kind":"module","full_name":"DBX","name":"DBX","abstract":false,"superclass":null,"ancestors":[],"locations":[{"filename":"src/dbx.cr","line_number":59,"url":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L59"}],"repository_name":"dbx","program":false,"enum":false,"alias":false,"aliased":"","const":false,"constants":[],"included_modules":[],"extended_modules":[],"subclasses":[],"including_types":[],"namespace":null,"doc":"DBX is a helper to handle multi DBs using the compatible drivers\nwith the common `crystal-db` module.\n\nExample with PostgreSQL:\n\n```\n# Connection URI / DSL https://www.postgresql.org/docs/current/libpq-connect.html#h5o-9\ndb = DBX.open(\"app\", \"postgres://...\", true)\n\npp DBX.db?(\"app\") ? \"defined\" : \"not defined\"\n\ndb.query \"select id, created_at, email from users\" do |rs|\n  rs.each do\n    id = rs.read(Int32)\n    created_at = rs.read(Time)\n    email = rs.read(String)\n    puts \"##{id}: #{email} #{created_at}\"\n  end\nend\n\n# Closes all connections of this DB entry point and remove this DB entry point.\nDBX.destroy(\"app\")\n```\n\nModel:\n\n```\nclass User\n  include JSON::Serializable\n  include DB::Serializable\n  include DB::Serializable::NonStrict\n\n  property lang : String\n\n  @[JSON::Field(key: \"firstName\")]\n  property first_name : String?\nend\n\ndb = DBX.open \"app\", App.cfg.db_uri\n\nuser = User.from_rs(db.query(\"SELECT id, lang, first_name FROM users\"))\npp user.to_json\n\nuser = User.from_json \"{\\\"lang\\\":\\\"fr\\\",\\\"firstName\\\":\\\"Nico\\\"}\"\npp user\n```\n\nResources:\n- https://crystal-lang.github.io/crystal-db/api/index.html","summary":"<p>DBX is a helper to handle multi DBs using the compatible drivers with the common <code>crystal-db</code> module.</p>","class_methods":[{"id":"db(name:String,uri:String,strict=false):DB::Database-class-method","html_id":"db(name:String,uri:String,strict=false):DB::Database-class-method","name":"db","doc":"Same as `.open`.","summary":"<p>Same as <code><a href=\"DBX.html#open(name:String,uri:String,strict=false):DB::Database-class-method\">.open</a></code>.</p>","abstract":false,"args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"},{"name":"uri","doc":null,"default_value":"","external_name":"uri","restriction":"String"},{"name":"strict","doc":null,"default_value":"false","external_name":"strict","restriction":""}],"args_string":"(name : String, uri : String, strict = <span class=\"n\">false</span>) : DB::Database","source_link":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L81","def":{"name":"db","args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"},{"name":"uri","doc":null,"default_value":"","external_name":"uri","restriction":"String"},{"name":"strict","doc":null,"default_value":"false","external_name":"strict","restriction":""}],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"DB::Database","visibility":"Public","body":"self.open(name, uri, strict)"}},{"id":"db(name:String):DB::Database-class-method","html_id":"db(name:String):DB::Database-class-method","name":"db","doc":"Uses a given DB entry point.","summary":"<p>Uses a given DB entry point.</p>","abstract":false,"args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"}],"args_string":"(name : String) : DB::Database","source_link":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L76","def":{"name":"db","args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"}],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"DB::Database","visibility":"Public","body":"@@dbs[name]"}},{"id":"db?(name:String):Bool-class-method","html_id":"db?(name:String):Bool-class-method","name":"db?","doc":"Checks that a DB entry point exists.","summary":"<p>Checks that a DB entry point exists.</p>","abstract":false,"args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"}],"args_string":"(name : String) : Bool","source_link":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L71","def":{"name":"db?","args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"}],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"Bool","visibility":"Public","body":"@@dbs.has_key?(name)"}},{"id":"dbs:DBHashType-class-method","html_id":"dbs:DBHashType-class-method","name":"dbs","doc":"Returns all `DB::Database` instances.","summary":"<p>Returns all <code>DB::Database</code> instances.</p>","abstract":false,"args":[],"args_string":" : DBHashType","source_link":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L66","def":{"name":"dbs","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"DBHashType","visibility":"Public","body":"@@dbs"}},{"id":"destroy(name:String)-class-method","html_id":"destroy(name:String)-class-method","name":"destroy","doc":"Closes all connections of the DB entry point *name*\nand remove the *name* DB entry point.","summary":"<p>Closes all connections of the DB entry point <em>name</em> and remove the <em>name</em> DB entry point.</p>","abstract":false,"args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"}],"args_string":"(name : String)","source_link":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L101","def":{"name":"destroy","args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"}],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"if self.db?(name)\n  (self.db(name)).close\n  @@dbs.delete(name)\nend"}},{"id":"destroy:Tuple(Int32,Int32)-class-method","html_id":"destroy:Tuple(Int32,Int32)-class-method","name":"destroy","doc":"Destroy all DB entry points and and their connections.","summary":"<p>Destroy all DB entry points and and their connections.</p>","abstract":false,"args":[],"args_string":" : Tuple(Int32, Int32)","source_link":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L109","def":{"name":"destroy","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"Tuple(Int32, Int32)","visibility":"Public","body":"size = @@dbs.size\n@@dbs.each_key do |name|\n  self.destroy(name)\nend\n{@@dbs.size, size}\n"}},{"id":"open(name:String,uri:String,strict=false):DB::Database-class-method","html_id":"open(name:String,uri:String,strict=false):DB::Database-class-method","name":"open","doc":"Ensures only once DB entry point by *name* is open.\nIf the DB entry point *name* is already initialized, it is returned.\nRaises an error if *strict* is *true* and the DB entry point *name* is\nalready opened.","summary":"<p>Ensures only once DB entry point by <em>name</em> is open.</p>","abstract":false,"args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"},{"name":"uri","doc":null,"default_value":"","external_name":"uri","restriction":"String"},{"name":"strict","doc":null,"default_value":"false","external_name":"strict","restriction":""}],"args_string":"(name : String, uri : String, strict = <span class=\"n\">false</span>) : DB::Database","source_link":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L89","def":{"name":"open","args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"},{"name":"uri","doc":null,"default_value":"","external_name":"uri","restriction":"String"},{"name":"strict","doc":null,"default_value":"false","external_name":"strict","restriction":""}],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"DB::Database","visibility":"Public","body":"if @@dbs.has_key?(name)\n  if strict\n  else\n    return @@dbs[name]\n  end\n  raise(\"'#{name}' DB entry point is already opened\")\nend\n@@dbs[name] = DB.open(uri)\n"}},{"id":"pool_open_connections(name:String):Int32-class-method","html_id":"pool_open_connections(name:String):Int32-class-method","name":"pool_open_connections","doc":"Gets the number of the connections opened in the pool of *name*.","summary":"<p>Gets the number of the connections opened in the pool of <em>name</em>.</p>","abstract":false,"args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"}],"args_string":"(name : String) : Int32","source_link":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L126","def":{"name":"pool_open_connections","args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"}],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"Int32","visibility":"Public","body":"pool_stats = self.pool_stats(name)\nif pool_stats\nelse\n  return 0\nend\npool_stats.open_connections\n"}},{"id":"pool_stats(name:String):DB::Pool::Stats?-class-method","html_id":"pool_stats(name:String):DB::Pool::Stats?-class-method","name":"pool_stats","doc":"Pool stats\nhttps://crystal-lang.github.io/crystal-db/api/latest/DB/Pool.html","summary":"<p>Pool stats https://crystal-lang.github.io/crystal-db/api/latest/DB/Pool.html</p>","abstract":false,"args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"}],"args_string":"(name : String) : DB::Pool::Stats?","source_link":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L121","def":{"name":"pool_stats","args":[{"name":"name","doc":null,"default_value":"","external_name":"name","restriction":"String"}],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"DB::Pool::Stats | ::Nil","visibility":"Public","body":"if self.db?(name)\n  (self.db(name)).pool.stats\nend"}}],"constructors":[],"instance_methods":[],"macros":[],"types":[{"html_id":"dbx/DBX/DBHashType","path":"DBX/DBHashType.html","kind":"alias","full_name":"DBX::DBHashType","name":"DBHashType","abstract":false,"superclass":null,"ancestors":[],"locations":[{"filename":"src/dbx.cr","line_number":60,"url":"https://github.com/Nicolab/crystal-dbx/blob/eec21ae2a9bb78dde89d171f8634f5767bf7055b/src/dbx.cr#L60"}],"repository_name":"dbx","program":false,"enum":false,"alias":true,"aliased":"Hash(String, DB::Database)","const":false,"constants":[],"included_modules":[],"extended_modules":[],"subclasses":[],"including_types":[],"namespace":{"html_id":"dbx/DBX","kind":"module","full_name":"DBX","name":"DBX"},"doc":null,"summary":null,"class_methods":[],"constructors":[],"instance_methods":[],"macros":[],"types":[]}]}]}})