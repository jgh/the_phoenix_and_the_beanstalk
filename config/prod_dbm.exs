use Mix.Config

config :the_phoenix_and_the_beanstalk, ThePhoenixAndTheBeanstalk.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost",
        port: {:system, "PORT"}],
  cache_static_manifest: "priv/static/manifest.json",
  server: true
# Do not print debug messages in production
config :logger, level: :info

import_config "prod.secret.exs"

# Configure your database
config :the_phoenix_and_the_beanstalk, ThePhoenixAndTheBeanstalk.Repo,
  adapter: Ecto.Adapters.Postgres,
  hostname:    System.get_env("RDS_HOSTNAME"),
  port:        System.get_env("RDS_PORT"),
  username:    System.get_env("RDS_USERNAME"),
  password:    System.get_env("RDS_PASSWORD"),
  database:    System.get_env("RDS_DB_NAME"),
  pool_size: 1
