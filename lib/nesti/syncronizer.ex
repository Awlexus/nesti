defmodule Nesti.Syncronizer do
  use GenServer

  def start_link(preloads) do
    GenServer.start_link(__MODULE__, preloads)
  end

  def init(preloads) do
    {mapping, count} = preloads_to_map(preloads)
    counter = :counters.new(count, [:atomics])

    {:ok, {counter, mapping}}
  end

  def handle_call({:next, []}, _from, {counter, mapping} = state) do
    index =
      mapping
      |> Map.get(:__index)
      |> next_index(counter)

    {:reply, index, state}
  end

  def handle_call({:next, stack}, _from, {counter, mapping} = state) do
    index =
      mapping
      |> get_in(stack)
      |> get_index(counter)

    {:reply, index, state}
  end

  def next(syncronizer, preload) do
    GenServer.call(syncronizer, {:next, preload}, :infinity)
  end

  def preloads_to_map(preloads) do
    counter = :counters.new(1, [])

    {preloads_to_map(preloads, counter), :counters.get(counter, 1)}
  end

  defp preloads_to_map(preloads, counter) when is_list(preloads) do
    Enum.into(preloads, %{__index: next_index(counter)}, &preloads_to_map(&1, counter))
  end

  defp preloads_to_map({preload, sub_preloads}, counter) when is_list(sub_preloads) do
    {preload,
     Enum.into(sub_preloads, %{__index: next_index(counter)}, &preloads_to_map(&1, counter))}
  end

  defp preloads_to_map({preload, sub_preload}, counter) do
    {preload,
     %{
       :__index => next_index(counter),
       sub_preload => %{__index: next_index(counter)}
     }}
  end

  defp preloads_to_map(preload, counter) do
    {preload, next_index(counter)}
  end

  defp next_index(index \\ 1, counter) do
    :counters.add(counter, index, 1)
    :counters.get(counter, index)
  end

  defp get_index(%{__index: index}, counter) do
    next_index(index, counter)
  end

  defp get_index(index, counter) when is_integer(index) do
    next_index(index, counter)
  end
end
