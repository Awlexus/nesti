defmodule Nesti.Support.User do
  use Nesti.Schema
  alias Nesti.Support.Post
  import Ecto.Changeset

  schema "users" do
    field(:first_name, :string)
    field(:surname, :string)
    field(:email, :string)

    has_many(:posts, Post)
  end

  @impl Nesti.Schema
  def flat_changeset(user, data) do
    cast(user, data, [:first_name, :surname, :email])
  end

  @impl Nesti.Schema
  def changeset(user, data) do
    user
    |> cast(data, [:first_name, :surname, :email])
    |> cast_assoc(:posts)
  end

  @impl Nesti.Schema
  def equal_keys(), do: :email
end
