defmodule Livebooks.Cache do
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
      _ = :ets.new(@table_name, [:set, :named_table, :public])
      # We don't actually need to start/supervise any process
      :ignore
    else
      {:error, {:already_started, self()}}
    end
  end

  def store(key, value) do
    :ets.insert(@table_name, {key, value})
    value
  end

  def lookup(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, value}] -> value
      _ -> nil
    end
  end
end
