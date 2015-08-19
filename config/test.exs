use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :the_phoenix_and_the_beanstalk, ThePhoenixAndTheBeanstalk.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Set a higher stacktrace during test
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :the_phoenix_and_the_beanstalk, ThePhoenixAndTheBeanstalk.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "the_phoenix_and_the_beanstalk_test",
  pool: Ecto.Adapters.SQL.Sandbox
