defmodule Nesti.Support.Repo.Migrations.AddTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:first_name, :string)
      add(:surname, :string)
      add(:email, :string)
    end

    create table(:posts) do
      add(:message, :string)
      add(:user_id, references(:users, on_delete: :delete_all, on_update: :update_all))

      timestamps()
    end

    create table(:comments) do
      add(:message, :string)
      add(:user_id, references(:users, on_delete: :delete_all, on_update: :update_all))
      add(:post_id, references(:posts, on_delete: :delete_all, on_update: :update_all))

      timestamps()
    end
  end
end
