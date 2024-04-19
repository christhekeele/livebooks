defmodule Livebook.Module do
  require Matcha.Table.ETS

  @table_name __MODULE__

  @doc false
  def child_spec(options) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, options}
    }
  end

  @doc false
  def start_link(_options \\ []) do
    if :ets.whereis(@table_name) == :undefined do
      _ = :ets.new(@table_name, [:ordered_set, :named_table, :public])
      # We don't actually need to start/supervise any process
      :ignore
    else
      {:error, {:already_started, self()}}
    end
  end

  @doc """
  Defines a module that can be iterated upon within in a livebook.

  Extending `defmodule/2`, when defining a module,
  in the `options` you can specify a `v: integer` version for it.
  You can then later redefine it in your livebook with an incremented version number
  without error.

  Other accepted `options`:

  - `:debug` *(**default: `false`**, allowed: `true | false`)*

    When `true`, inspects the full generated code for this version of the `module`.

  ### Examples

  ```elixir
  defmodule Foo, v: 1 do
    def hello, do: :world
  end

  defmodule Foo, v: 2, debug: true do
    defoverridable hello: 0
    def hello, do: :"livebook_\#{super()}"
  end

  #=> defmodule :"Elixir.Foo.__v2" do
  #=>   def hello do
  #=>     :world
  #=>   end
  #=>
  #=>   defoverridable hello: 0
  #=>
  #=>   def hello do
  #=>     :"livebook_\#{super()}"
  #=>   end
  #=> end
  #=>
  #=> alias :"Elixir.Foo.__v2", as: Foo

  Foo.hello()
  #=> :livebook_world
  ```

  ### Mechanism

  Under the covers, the code provided to define each version of the `module` is stored,
  and retreived and prepended to the code in later versions.
  This means that functions defined in previous versions can be patched without warning by
  using `defoverridable/1` just before re-defining them, and invoked in the new definition
  using `super/1`.

  Each version of the module is compiled and available as `"\#{module}.__v\#{version_specifier}"`,
  then `alias/2`'d to `module` so code later in the livebook references the latest version,
  similar to how Elixir's immutable variables work by versioning reassignments to them under the hood.

  This solution is a bit of a hack, and comes with the caveats:

  - The `module` name must be top-level: ex. `FooBar` rather than `Foo.Bar`.
  - The `v: version` must be a non-negative integer.

  Inspired by [this macro](https://github.com/brettbeatty/experiments_elixir/blob/master/module_patching.livemd)
  and [this forum post](https://elixirforum.com/t/how-do-i-redifine-modules-in-livebook/56442/2).
  """
  defmacro defmodule(
             _module = {:__aliases__, _, [alias | []]},
             _options = [{:v, version} | options],
             _code = [do: block]
           )
           when is_integer(version) and version >= 0 do
    {debug, options} = Keyword.pop(options, :debug, false)

    if options != [] do
      raise ArgumentError,
            "unexpected options provided to `#{inspect(__MODULE__)}.defmodule/3`: #{inspect(options)}"
    end

    module_alias = Macro.expand({:__aliases__, [alias: false], [:"Elixir", alias]}, __CALLER__)
    version = Macro.expand(version, __CALLER__)
    version_namespace = "__v#{version}" |> String.to_atom()
    module = module_alias |> Module.concat(version_namespace)
    add_version(module_alias, version, block)

    code =
      history(module_alias, version)
      |> Macro.prewalk(fn
        # Re-anchor any references to the core module,
        #  overwriting the post-module-def alias,
        #  so that other modules can be namespaced under it
        #  and referenced correctly
        {:__aliases__, meta, [^alias | rest]} ->
          {:__aliases__, meta, [:"Elixir", alias | rest]}

        code ->
          code
      end)

    quote do
      defmodule unquote(module), do: unquote(code)
      alias unquote(module), as: unquote(module_alias)
    end
    |> tap(fn macro ->
      if debug do
        macro
        |> Macro.to_string()
        |> Code.format_string!()
        |> IO.puts()
      end
    end)
  end

  @doc false
  def add_version(module, version, block) do
    :ets.insert(@table_name, {{module, version}, block})
  end

  @doc false
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

  defp block(block = {:__block__, _meta, _code}), do: block
  defp block(code), do: {:__block__, [], code}
end
