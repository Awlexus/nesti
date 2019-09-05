defmodule NestiTest do
  use ExUnit.Case, async: true
  use Nesti.Support.RepoCase
  doctest Nesti
  alias Nesti.Support.{Repo, User}
  import Ecto.Query, only: [from: 2]

  setup_all do
    Agent.start(fn -> {0, 0, 0} end, name: :counter)

    {:ok, []}
  end

  test "Inserts the nested data" do
    users = user_list(3, 4, 5)
    Nesti.diff_schema(users, User, Repo) |> Repo.transaction()
    persisted_users = get_persisted(users)

    [posts, persisted_posts] = mins([users, persisted_users], :email, :posts)
    [comments, persisted_comments] = mins([posts, persisted_posts], :email, :comments)

    assert length(users) == length(persisted_users)
    assert sort_map(users, & &1.email) == sort_map(persisted_users, & &1.email)

    assert length(posts) == length(persisted_posts)
    assert sort_map(posts, & &1.message) == sort_map(persisted_posts, & &1.message)

    assert length(comments) == length(persisted_comments)
    assert sort_map(comments, & &1.message) == sort_map(persisted_comments, & &1.message)
  end

  test "Correctly updates database" do
    # Keeping this test minimal and flat
    users = [user] = user_list(1, 1, 1)
    Nesti.diff_schema(users, User, Repo) |> Repo.transaction()

    users =
      [user] = [
        user
        |> Map.put(:first_name, "Ro")
        |> Map.put(:surname, "bob")
      ]

    Nesti.diff_schema(users, User, Repo) |> Repo.transaction()

    persisted_user = get_persisted(user)

    [post] = user.posts
    [persisted_post] = persisted_user.posts
    [_] = post.comments
    [_] = persisted_post.comments

    assert persisted_user.first_name == user.first_name
    assert persisted_user.first_name == user.first_name
  end

  test "deletes removed entities" do
    users = [user] = user_list(1, 5, 1)

    Nesti.diff_schema(users, User, Repo)
    middle_post = Enum.at(user.posts, 2)
    user = %{user | posts: [middle_post]}
    [post] = user.posts
    Nesti.diff_schema([user], User, Repo) |> Repo.transaction()

    persisted_user = get_persisted(user)
    [persisted_post] = persisted_user.posts

    assert user.email == persisted_user.email
    assert post.message == persisted_post.message
  end

  test "inserts new entities" do
    users = [user] = user_list(1, 5, 1)
    test_message = "This is a new message"

    Nesti.diff_schema(users, User, Repo) |> Repo.transaction()
    user = %{user | posts: [%{message: test_message} | user.posts]}
    Nesti.diff_schema([user], User, Repo) |> Repo.transaction()

    persisted_user = get_persisted(user)

    assert Enum.find(persisted_user.posts, fn post -> post.message == test_message end)
    assert length(persisted_user.posts) == length(user.posts)
  end

  defp get_persisted(users) when is_list(users),
    do:
      Repo.all(from(u in User, where: u.email in ^Enum.map(users, & &1.email))) |> preload_user()

  defp get_persisted(user), do: Repo.get_by(User, email: user.email) |> preload_user()

  defp preload_user(user_s), do: Repo.preload(user_s, posts: :comments)

  defp sort_map(list, fun), do: list |> Enum.map(fun) |> Enum.sort()

  defp user_list(user_count, post_count, comment_count) do
    build_list(user_count, fn ->
      %{
        first_name: "John",
        surname: "Cena",
        email: sequence(0, &"john.cena#{&1}.example.com"),
        posts:
          build_list(post_count, fn ->
            %{
              message: sequence(1, &"This is Post Nr. #{&1}"),
              comments:
                build_list(comment_count, fn ->
                  %{
                    message: sequence(2, &"This is Comment Nr. #{&1}")
                  }
                end)
            }
          end)
      }
    end)
  end

  defp build_list(count, fun) do
    Enum.map(1..count, fn _ ->
      fun.()
    end)
  end

  defp sequence(index, fun) do
    Agent.get_and_update(:counter, fn state ->
      count = elem(state, index)

      {fun.(count), put_elem(state, index, count + 1)}
    end)
  end

  defp mins(enums, min_key, key) do
    enums
    |> Enum.map(fn enum ->
      enum
      |> Enum.min_by(&Map.get(&1, min_key))
      |> Map.get(key)
    end)
  end
end
