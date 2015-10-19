use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :isucon5q, Isucon5q.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :isucon5q, Isucon5q.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "",
  database: "isucon5q_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
