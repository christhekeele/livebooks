defmodule Livebook do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    [Livebook.Module]
    |> Supervisor.start_link(strategy: :one_for_one, name: Livebook.Supervisor)
  end
end
