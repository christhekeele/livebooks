defmodule Livebooks.Router do
  use Plug.Router
  alias Plug.Conn

  @content :livebooks |> :code.priv_dir()
  @livebooks @content |> Path.join("**/*.livemd") |> Path.wildcard()

  @livebook_routes @livebooks |> Enum.map(&(&1 |> Path.relative_to(@content) |> Path.rootname()))

  plug(Plug.Logger, log: :debug)

  static_files = Enum.map(@livebook_routes, &(&1 <> ".livemd"))

  plug(Plug.Static,
    at: "/",
    from: {:livebooks, "/priv"},
    only_matching: static_files,
    brotli: true,
    gzip: true
  )

  plug(:match)
  plug(:dispatch)

  for route <- @livebook_routes do
    get "/#{route}" do
      livebook_url =
        conn
        |> request_url()
        |> Kernel.<>(".livemd")

      destination_url = "https://livebook.dev/run?url=#{URI.encode(livebook_url)}"

      conn |> Conn.put_resp_header("location", destination_url) |> send_resp(:found, "")
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
