# This file is part of "craft" framework.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/craft-framework/craft
# ------------------------------------------------------------------------------

FROM crystallang/crystal:0.35.1

ARG user=app
ARG uid=1000

WORKDIR /tmp

# Install deps
RUN apt-get update -qq && apt-get install -y --no-install-recommends git htop apt-utils libpq-dev curl

# Install watchexec & just
RUN curl -L >watchexec.tar.xz https://github.com/watchexec/watchexec/releases/download/1.14.1/watchexec-1.14.1-i686-unknown-linux-musl.tar.xz \
  && tar -xvf watchexec.tar.xz \
  && mv watchexec-1.14.1-i686-unknown-linux-musl/watchexec /usr/local/bin/ \
  && rm watchexec.tar.xz \
  && rm -rf watchexec-1.14.1-i686-unknown-linux-musl \
  && watchexec --version \
  && curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin/ \
  && just --version

# create user and grant the perm on the source file folder
RUN useradd -c 'App user' -m $user -o -u $uid
WORKDIR /app

# copy project files
COPY --chown=${user}:${user} ./shard.yml ./
COPY --chown=${user}:${user} ./justfile ./

COPY --chown=${user}:${user} ./src ./
COPY --chown=${user}:${user} ./spec ./

RUN echo "CMD_USER: $CMD_USER" \
  && rm -rf /app/lib /app/shard.lock \
  && chown ${user}:${user} -R ./

USER ${user}

# let it at the end. This way when there is a modification of the arg `APP_ENV`
# it does not rebuild every previous commands
ARG app_env=local
ENV APP_ENV=${app_env}

# default command
CMD [ "/bin/bash" ]