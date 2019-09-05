defmodule Nesti.Support.Post do
  use Nesti.Schema
  alias Nesti.Support.{Comment, User}
  import Ecto.Changeset

  schema "posts" do
    field(:message, :string)

    belongs_to(:user, User)
    has_many(:comments, Comment)
    timestamps()
  end

  @impl Nesti.Schema
  def flat_changeset(comment, data) do
    cast(comment, data, [:message])
  end

  @impl Nesti.Schema
  def changeset(comment, data) do
    comment
    |> cast(data, [:message])
    |> cast_assoc(:comments)
  end

  @impl Nesti.Schema
  def equal_keys(), do: :message
end
