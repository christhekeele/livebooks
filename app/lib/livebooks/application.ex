defmodule Livebooks.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    [
      {Plug.Cowboy, scheme: :http, plug: Livebooks.Router, options: [port: 4001]}
    ]
    |> Supervisor.start_link(
      strategy: :one_for_one,
      name: Livebooks.Supervisor
    )
  end
end
