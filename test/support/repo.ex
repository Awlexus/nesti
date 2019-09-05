defmodule Nesti.Support.Repo do
  use Ecto.Repo,
    otp_app: :nesti,
    adapter: Ecto.Adapters.Postgres
end
