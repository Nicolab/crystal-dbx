# :sparkles: DBX

[![CI Status](https://github.com/Nicolab/crystal-dbx/workflows/CI/badge.svg?branch=master)](https://github.com/Nicolab/crystal-dbx/actions) [![GitHub release](https://img.shields.io/github/release/Nicolab/crystal-dbx.svg)](https://github.com/Nicolab/crystal-dbx/releases) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://nicolab.github.io/crystal-dbx/)

* DB connections manager
* Query builder
* ORM

DBX is a [Crystal lang](https://crystal-lang.org) module to query the database, built on top of [crystal-db](https://github.com/crystal-lang/crystal-db) (common API for DB drivers).

DBX is designed in a decoupled way to embed only the necessary features (multi-connections manager, query builder, query executor and ORM).

## Documentation

* 🚀 [Guide](/guide/README.md)
* 📘 [API doc](https://nicolab.github.io/crystal-dbx/)
* :bookmark_tabs: [Spec tests](https://github.com/Nicolab/crystal-dbx/tree/master/spec)

## Contributing

1. Fork it (<https://github.com/Nicolab/crystal-dbx/fork>).
2. Create your feature branch (`git checkout -b my-new-feature`).
3. See [Development](#Development).
4. Commit your changes (`git commit -am 'Add some feature'`).
5. Push to the branch (`git push origin my-new-feature`).
6. Create a new Pull Request.

### Development

1. You only need Git, Docker and Docker-compose installed on your machine.
2. Clone this repo and run `./scripts/prepare`.
3. Run first `docker-compose up`,
    1. then enter to container `docker-compose exec test_pg bash` (or `test_sqlite` service),
    2. into the container `just dev-spec`.
4. Check the project before committing or pushing, from the host: `./scripts/check`

It's just Docker and docker-compose, you can directly type all the commands Docker and docker-compose.

✨ Example:

_Terminal 1_

```sh
# Start the dev stack
docker-compose up
```

_Terminal 2_

```sh
# enter in the test_pg container
docker-compose exec test_pg bash

# then in the test_pg container
crystal run ./src/app.cr

# or with a recipe (helper)
just dev-spec # <= auto reload when the code change

# recipe list
just --list
```

Also, quickly:

* `docker-compose run --rm test_pg crystal spec`
* or `docker-compose run --rm test_pg just dev-spec`
* when you are done: `docker-compose down --remove-orphans`

## LICENSE

[MIT](https://github.com/Nicolab/crystal-dbx/blob/master/LICENSE) (c) 2020, Nicolas Talle.

## Author

* [Nicolas Talle (@Nicolab)](https://github.com/Nicolab) - Creator and maintainer
* This project is useful to you? [Sponsor the developer](https://github.com/sponsors/Nicolab)
