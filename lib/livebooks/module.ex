defmodule Livebooks.Module do
  @moduledoc false
  require Matcha.Table.ETS

  @table_name __MODULE__

  def child_spec(options) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, options}
    }
  end

  def start_link(_options \\ []) do
    if :ets.whereis(@table_name) == :undefined do
      _ = :ets.new(@table_name, [:ordered_set, :named_table, :public])
      # We don't actually need to start/supervise any process
      :ignore
    else
      {:error, {:already_started, self()}}
    end
  end

  def add_version(module, version, block) do
    :ets.insert(@table_name, {{module, version}, block})
  end

  def history(module, since_version) do
    @table_name
    |> Matcha.Table.ETS.select do
      {{^module, version}, block} when version <= since_version -> block
    end
    |> Enum.flat_map(&unblock/1)
    |> block
  end

  defp unblock({:__block__, _meta, block}), do: block
  defp unblock(ast), do: [ast]

  # defp block(block = {:__block__, _meta, _code}), do: block
  defp block(code), do: {:__block__, [], code}
end
