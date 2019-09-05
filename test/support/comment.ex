defmodule Nesti.Support.Comment do
  use Nesti.Schema
  alias Nesti.Support.{Post, User}
  import Ecto.Changeset

  @comment_keys [:message, :user_id, :post_id]
  schema "comments" do
    field(:message, :string)

    belongs_to(:user, User)
    belongs_to(:post, Post)
    timestamps()
  end

  @impl Nesti.Schema
  def flat_changeset(comment, data) do
    cast(comment, data, @comment_keys)
  end

  @impl Nesti.Schema
  def changeset(comment, data) do
    cast(comment, data, @comment_keys)
  end

  @impl Nesti.Schema
  def equal_keys(), do: :message
end
