FROM node:8.10.0 as build-front
WORKDIR /app/front

RUN apt update && \
    apt install -y --no-install-recommends curl ca-certificates build-essential git && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./front/*.json /app/front/
RUN npm i && ./node_modules/.bin/bower i --allow-root

COPY ./front /app/front/
ENV NODE_ENV production
RUN npm run webpack


FROM elixir:1.6-slim as build-server
ENV MIX_ENV prod
WORKDIR /app

RUN apt update && \
    apt install -y --no-install-recommends curl ca-certificates build-essential sqlite3 dos2unix && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./mix.* /app/

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

COPY ./config /app/config
COPY ./lib /app/lib
COPY ./priv /app/priv
COPY ./rel /app/rel
COPY --from=build-front /app/priv/static /app/priv/static

RUN mix phx.digest --force && \
    mix compile --force && \
    mix release

RUN dos2unix /app/_build/prod/rel/crafters/releases/0.0.1/commands/*.sh


FROM elixir:1.6-slim

ENV PORT 80
EXPOSE 80

VOLUME ["/var/crafters"]

CMD ["/app/_build/prod/rel/crafters/bin/crafters", "run"]

RUN apt update && \
    apt install -y --no-install-recommends sqlite3 && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=build-server /app/_build /app/_build

