import Config

if Mix.env() == :test do
  config :nesti, Nesti.Support.Repo,
    username: "postgres",
    password: "postgres",
    database: "nesti_test",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox

  config :nesti, ecto_repos: [Nesti.Support.Repo]
end
