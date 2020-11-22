# This file is part of "craft" framework.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/craft-framework/craft
# ------------------------------------------------------------------------------

main_file := env_var_or_default("APP_MAIN", "app.cr")

# Lists recipes
default:
  @just --list

# Simple build
build FILE='app' FLAGS='--progress':
  crystal build ./src/{{main_file}} {{FLAGS}} -o {{FILE}}
  @echo build done!

# Build release
build-release FILE='app' FLAGS='--no-debug --progress':
  crystal build ./src/{{main_file}} --release {{FLAGS}} -o {{FILE}}
  @echo build release done!

# Runs the spec
spec FILES='' FLAGS='--progress':
  crystal spec {{FLAGS}} {{FILES}}
  @echo spec done!

alias test := spec

# Start watching files in APP_ENV=local, run the spec
develop-spec *CMD:
 #!/bin/bash
  APP_ENV=${APP_ENV:=local}
  LOG=${LOG:=debug}
  echo "Spec - Start watching files in APP_ENV=${APP_ENV}"
  echo "Happy coding ;-)"
  echo "..."
  watchexec -w src -w spec --exts cr,ecr -r -- crystal spec --error-trace -p -- '{{CMD}}'

alias dev-spec := develop-spec

# Start watching files in APP_ENV=local, run the app
# Example:
# just develop 'gen framework'
# or ./scripts/develop 'gen framework'
develop *CMD:
 #!/bin/bash
  APP_ENV=${APP_ENV:=local}
  LOG=${LOG:=debug}
  watchexec -w src -w spec --exts cr,ecr --clear -r -s SIGKILL \
    -- "
      echo 'Craft - Start watching files in APP_ENV=${APP_ENV}'; \
      echo 'Run: {{CMD}}\n...\n'; \
      crystal run ./src/{{main_file}} -p -- {{CMD}} \
    "

alias dev := develop

# Start watching files in APP_ENV=local, build the app
# Example:
# just develop-build 'gen framework'
# or ./scripts/just "dev-build 'gen framework'"
develop-build *CMD:
 #!/bin/bash
  APP_ENV=${APP_ENV:=local}
  LOG=${LOG:=debug}
  watchexec -w src -w spec --exts cr,ecr --clear -r -s SIGKILL \
    -- "crystal build ./src/{{main_file}} -o app -p; \
      echo 'App - Start watching files in APP_ENV=${APP_ENV}'; \
      echo 'Run: ./app {{CMD}}\n...\n'; \
      ./app {{CMD}} \
    "

alias dev-build := develop-build

# Crystal tool format ./src/ ./spec
format:
  crystal tool format ./src/ ./spec
  @# format done!

alias f := format

# Count non-empty lines of code in `src` folder
sloc:
	@cat src/**/*.cr | sed '/^\s*$/d' | wc -l

# Count non-empty lines of code in `spec` folder
sloc-spec:
	@cat spec/**/*.cr | sed '/^\s*$/d' | wc -l

# Prints system info
system-info:
  @echo "- `uname -a`"
  @echo "- OS: {{os()}} {{arch()}}"
  @echo "- OS family: {{os_family()}}"

# Check the code
@lint:
    echo Checking for FIXME/TODO...
    ! grep --color -Enr 'FIXME|TODO' src/*.cr
    ! grep --color -Enr 'FIXME|TODO' spec/*.cr
    echo Checking for 'spec focus: true'...
    ! grep --color -Enr 'focus: true do' spec/*.cr
    echo Checking for long lines...
    ! grep --color -Enr '.{101}' src/**.cr
    ! grep --color -Enr '.{101}' spec/**.cr
    crystal tool format --check ./src ./spec
    @# check done!

# Check and clean the workspace
clean: format lint spec
  @rm -f ./app
  @echo All done!

# ------------------------------------------------------------------------------
# Craft framework recipes
# ------------------------------------------------------------------------------

# Start a HTTP server in APP_ENV=local, then watching files
develop-web *CMD:
  just develop web --routes {{CMD}}

alias dev-web := develop-web

# ------------------------------------------------------------------------------
# App recipes
# ------------------------------------------------------------------------------

# ...