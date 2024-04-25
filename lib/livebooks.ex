defmodule Livebooks do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    [
      Livebooks.Cache,
      Livebooks.Module
    ]
    |> Supervisor.start_link(strategy: :one_for_one, name: Livebooks.Supervisor)
  end
end
