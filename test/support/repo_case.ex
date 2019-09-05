defmodule Nesti.Support.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Nesti.Support.Repo

      import Ecto
      import Ecto.Query
      import Ecto.Changeset
      import Nesti.Support.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Nesti.Support.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Nesti.Support.Repo, {:shared, self()})
    end

    :ok
  end
end
