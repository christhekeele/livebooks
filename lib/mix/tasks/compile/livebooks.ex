defmodule Mix.Tasks.Compile.Livebooks do
  use Mix.Task.Compiler

  require Logger

  @impl true
  def run(_args) do
    project = Mix.Project.config()
    livebook_search_paths = project[:livebook_paths] || ["lib"]

    base_dir =
      Mix.Project.project_file()
      |> Path.dirname()

    livebook_paths =
      livebook_search_paths
      |> Enum.flat_map(fn livebook_path ->
        [base_dir, livebook_path, "**", "*.livemd"]
        |> Path.join()
        |> Path.wildcard()
        |> Enum.map(&Path.relative_to(&1, base_dir))
      end)

    for livebook_path <- livebook_paths do
      {rel_dir, base, _ext} =
        {Path.dirname(livebook_path), Path.basename(livebook_path, ".livemd"),
         Path.extname(livebook_path)}

      output_path = Path.join([base_dir, "test", rel_dir, "#{base}_test.exs"])

      Task.async(fn ->
        compile(livebook_path, output_path)
      end)
    end
    |> Task.await_many()

    :ok
  end

  def compile(livebook_path, output_path) do
    output_dir = Path.dirname(output_path)

    livebook_elixir =
      livebook_path
      |> File.read!()
      |> Livebook.live_markdown_to_elixir()

    File.mkdir_p!(output_dir)
    File.write!(output_path, livebook_elixir)

    try do
      Code.string_to_quoted!(livebook_elixir,
        file: output_path,
        columns: true,
        emit_warnings: true
      )

      :ok
    rescue
      e in [EEx.SyntaxError, SyntaxError, TokenMissingError] ->
        message = Exception.message(e)

        diagnostic = %Mix.Task.Compiler.Diagnostic{
          compiler_name: "Livebook",
          file: livebook_path,
          position: {e.line, e.column},
          message: message,
          severity: :error
        }

        {:error, diagnostic}

      e ->
        message = Exception.message(e)

        diagnostic = %Mix.Task.Compiler.Diagnostic{
          compiler_name: "Livebook",
          file: livebook_path,
          position: {1, 1},
          message: message,
          severity: :error
        }

        # e.g. https://github.com/elixir-lang/elixir/issues/12926
        Logger.warning(
          "Unexpected parser error, please report it to elixir project https://github.com/elixir-lang/elixir/issues\n" <>
            Exception.format(:error, e, __STACKTRACE__)
        )

        {:error, diagnostic}
    end
  end
end
