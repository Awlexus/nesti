defmodule Nesti do
  alias Ecto.{Association, Multi, Query}
  alias Nesti.{Schema, Syncronizer}
  import Query, only: [preload: 2, from: 2]

  @default_config [delete_missing: true, insert_new: true, preload: :all]

  @type data :: [map]
  @type schema_module :: module

  @spec diff_schema(Ecto.Multi.t(), data, schema_module, Ecto.Repo.t()) :: Ecto.Multi.t()
  def diff_schema(multi \\ Multi.new(), data, schema, repo)
      when is_atom(schema) and is_atom(repo) do
    with {:schema, true} <- {:schema, is_schema?(schema)},
         {:repo, true} <- {:repo, behaviour?(repo, Ecto.Repo)} do
      preloads = get_preloads(schema)

      {:ok, syncronizer} = Syncronizer.start_link(preloads)

      persisted_data =
        schema
        |> preload(^preloads)
        |> repo.all()

      do_diff(multi, nil, syncronizer, [], data, persisted_data, schema)
    else
      {:schema, false} -> raise_behaviour(schema, Nesti.Schema)
      {:repo, false} -> raise_behaviour(repo, Ecto.Repo)
    end
  end

  defp do_diff(multi, parent, syncronizer, stack, data, persisted_data, schema) do
    config = Keyword.merge(@default_config, schema.__config__())

    pairs =
      data
      |> pair_data(persisted_data, schema)
      |> Enum.group_by(
        &elem(&1, 0),
        fn
          {_, data} -> data
          {_, data_a, data_b} -> {data_a, data_b}
        end
      )

    new = pairs[:new]
    deleted = pairs[:deleted]
    equal = pairs[:equal]

    multi =
      if new && config[:insert_new] do
        insert_new(multi, new, schema, parent, syncronizer, stack)
      else
        multi
      end

    multi =
      if deleted && config[:delete_missing] do
        delete_missing(multi, deleted, schema, syncronizer, stack)
      else
        multi
      end

    if equal do
      multi = update_equal(multi, equal, schema, syncronizer, stack)

      preloads = get_preloads_flat(schema)

      Enum.reduce(equal, multi, fn {equal_data, equal_persisted_data}, multi ->
        Enum.reduce(preloads, multi, fn {preload, child_schema, related_key}, multi ->
          [id_column] = schema.__schema__(:primary_key)

          do_diff(
            multi,
            {related_key, Map.get(equal_persisted_data, id_column)},
            syncronizer,
            stack ++ [preload],
            Map.get(equal_data, preload),
            Map.get(equal_persisted_data, preload),
            child_schema
          )
        end)
      end)
    else
      multi
    end
  end

  defp insert_new(multi, new, schema, parent, syncronizer, stack) do
    base =
      case parent do
        {key, id} -> struct(schema, [{key, id}])
        _ -> struct(schema)
      end

    Enum.reduce(new, multi, fn entry, multi ->
      Multi.insert(
        multi,
        {stack, Syncronizer.next(syncronizer, stack)},
        schema.changeset(base, entry)
      )
    end)
  end

  defp delete_missing(multi, deleted, schema, syncronizer, stack) do
    ids = Enum.map(deleted, & &1.id)

    Multi.delete_all(
      multi,
      {stack, Syncronizer.next(syncronizer, stack)},
      from(s in schema, where: s.id in ^ids)
    )
  end

  defp update_equal(multi, equal, schema, syncronizer, stack) do
    Enum.reduce(equal, multi, fn {data, persisted_data}, multi ->
      Multi.update(
        multi,
        {schema, Syncronizer.next(syncronizer, stack)},
        schema.flat_changeset(persisted_data, data)
      )
    end)
  end

  defp is_module?(%module{}), do: is_module?(module)
  defp is_module?(module), do: function_exported?(module, :__info__, 1)

  def is_schema?(schema), do: behaviour?(schema, Schema)

  defp behaviour?(module, behaviour) do
    if is_module?(module) do
      module.__info__(:attributes)
      |> Keyword.get_values(:behaviour)
      |> Enum.any?(fn [behaviour_] -> behaviour_ == behaviour end)
    else
      false
    end
  end

  defp get_preloads(schema) do
    schema
    |> has_many_associations()
    |> Enum.map(&{&1.field, get_preloads(&1.related)})
    |> Enum.map(&to_preload_list/1)
  end

  defp get_preloads_flat(schema) do
    schema
    |> has_many_associations()
    |> Enum.map(&{&1.field, &1.related, &1.related_key})
  end

  defp to_preload_list({key, []}), do: key
  defp to_preload_list({_key, _preloads} = keyword), do: keyword

  defp has_many_associations(schema) do
    config = schema.__config__()

    case Keyword.get(config, :preload, :all) do
      :all ->
        :associations
        |> schema.__schema__()

      :none ->
        []

      {:only, associations} ->
        associations
    end
    |> Enum.map(&schema.__schema__(:association, &1))
    |> Enum.filter(&is_has_many?/1)
  end

  defp is_has_many?(%Association.Has{cardinality: :many}), do: true
  defp is_has_many?(_), do: false

  defp pair_data(map_a, map_b, schema) do
    equal_keys = schema.equal_keys() |> List.wrap()

    map_equal_keys = fn list ->
      Enum.into(list, %{}, &{Map.take(&1, equal_keys), &1})
    end

    map_a_map = map_equal_keys.(map_a)
    map_b_map = map_equal_keys.(map_b)

    [map_a_map, map_b_map]
    |> Enum.flat_map(&Map.keys/1)
    |> Enum.uniq()
    |> Enum.reduce({map_a_map, map_b_map, []}, &map_diff/2)
    |> Tuple.to_list()
    |> List.last()
  end

  defp map_diff(key, {map_a, map_b, acc}) do
    {item_a, new_a} = Map.pop(map_a, key)
    {item_b, new_b} = Map.pop(map_b, key)

    result =
      case {item_a, item_b} do
        {_, nil} -> {:new, item_a}
        {nil, _} -> {:deleted, item_b}
        {_, _} -> {:equal, item_a, item_b}
      end

    {new_a, new_b, [result | acc]}
  end

  defp raise_behaviour(module, behaviour),
    do: raise("The module '#{module}' doesn't implement the behaviour '#{behaviour}'")
end
