sequence in nested build_list work properly

I use the following function to generate a nested resource during tests.
```elixir
defp user_list(user_count, post_count, comment_count) do
  Factory.build_list(user_count, :raw_user,
    posts:
      Factory.build_list(post_count, :raw_post,
        comments: Factory.build_list(comment_count, :raw_comment)
      )
  )
end
```
Both each of these has a sequence in it's definition.

When I call this function with the parameters `2, 2, 2` I get two users with identical posts and comments.
