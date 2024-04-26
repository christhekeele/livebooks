defmodule Mix.Tasks.Compile.Livebooks do
  use Mix.Task.Compiler

  require Logger

  @impl true
  def run(args) do
    Application.ensure_all_started(:livebooks)
    warnings_as_errors? = "--warnings-as-errors" in args
    project = Mix.Project.config()
    livebook_search_paths = project[:livebook_paths] || ["lib"]
    livebook_output_path = project[:livebook_output_dir] || Mix.Project.compile_path(project)

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

    case length(livebook_paths) do
      0 -> :ok
      1 -> Mix.Shell.IO.info("Compiling 1 file (.livemd)")
      n -> Mix.Shell.IO.info("Compiling #{n} files (.livemd)")
    end

    for livebook_path <- livebook_paths do
      {rel_dir, base} =
        {Path.dirname(livebook_path), Path.basename(livebook_path, ".livemd")}

      output_path = Path.join([livebook_output_path, rel_dir, "#{base}.exs"])

      output_dir = Path.dirname(output_path)

      {:ok, livebook_ast, comments} =
        livebook_path
        |> File.read!()
        |> Livebook.live_markdown_to_elixir()
        |> Code.string_to_quoted_with_comments(emit_warnings: false)

      {livebook_ast, comments} =
        livebook_ast
        |> Macro.postwalk(comments, fn
          mix_install = {{:., meta, [{:__aliases__, _, [:Mix]}, :install]}, _, install_args},
          comments ->
            # line = Keyword.fetch!(meta, :line)
            # IO.inspect(install_args)
            # {:mix_install, [%{line: line, comments]}
            {mix_install, comments}

          ast, comments ->
            {ast, comments}
        end)

      livebook_script =
        livebook_ast
        |> Code.quoted_to_algebra(comments: comments)
        |> Inspect.Algebra.format(%Inspect.Opts{}.width)
        |> IO.iodata_to_binary()
        |> tap(&IO.puts/1)

      File.mkdir_p!(output_dir)
      File.write!(output_path, livebook_script)

      output_path
    end
    |> Kernel.ParallelCompiler.require(return_diagnostics: true)
    |> case do
      {:ok, _mods, warnings} ->
        if warnings_as_errors? do
          {:error, warnings_to_diagnostics(warnings)}
        else
          :ok
        end

      {:error, errors, warnings} ->
        if warnings_as_errors? do
          {:error, errors_to_diagnostics(errors) ++ warnings_to_diagnostics(warnings)}
        else
          {:error, errors_to_diagnostics(errors)}
        end
    end
  end

  defp warnings_to_diagnostics(%{
         runtime_warnings: runtime_warnings,
         compile_warnings: compile_warnings
       }) do
    code_diagnostics_to_compile_diagnostics(runtime_warnings) ++
      code_diagnostics_to_compile_diagnostics(compile_warnings)
  end

  defp errors_to_diagnostics(errors) do
    code_diagnostics_to_compile_diagnostics(errors)
  end

  defp code_diagnostics_to_compile_diagnostics(diagnostics) do
    Enum.map(diagnostics, &code_diagnostic_to_compile_diagnostic/1)
  end

  defp code_diagnostic_to_compile_diagnostic(diagnostic) do
    %Mix.Task.Compiler.Diagnostic{
      compiler_name: "Livebook",
      details: diagnostic[:severity],
      file: diagnostic[:file],
      message: diagnostic[:message],
      position: diagnostic[:position],
      severity: diagnostic[:severity],
      source: diagnostic[:severity],
      span: diagnostic[:severity],
      stacktrace: diagnostic[:severity]
    }
  end
end
