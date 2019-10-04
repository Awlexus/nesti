defmodule Nesti.Schema do
  alias Ecto.{Changeset, Schema}

  @type configs :: [config]
  @type config :: {:delete_missing, boolean} | {:insert_new, boolean} | {:preload, preload_values}
  @type preload_values :: :all | :none | {:only, [atom]}

  @callback flat_changeset(Schema.t(), Changeset.data()) :: Changeset.t()
  @callback changeset(Schema.t(), Changeset.data()) :: Changeset.t()
  @callback equal_keys() :: atom | [atom]
  @callback __config__() :: configs()

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      @behaviour Nesti.Schema

      def __config__(), do: []
      defoverridable __config__: 0
    end
  end

  def take_equal_keys(%schema{} = data) do
    if Nesti.is_schema?(schema) do
      Map.take(data, schema.equal_keys)
    else
      %{}
    end
  end

  def take_equal_keys(_), do: %{}
end
