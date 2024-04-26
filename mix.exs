defmodule Livebooks.MixProject do
  use Mix.Project

  ####
  # Package stuff
  ##

  @app :livebooks
  @name "Chris Keele's Livebooks"
  @maintainers ["Chris Keele"]
  @licenses ["MIT"]

  @github_url "https://github.com/christhekeele/livebooks"
  @github_branch "latest"

  @version "VERSION" |> File.read!() |> String.trim() |> Version.parse!()

  ####
  # Site stuff
  ##

  @homepage_domain "livebooks.chriskeele.com"
  @homepage_url "https://#{@homepage_domain}"

  @title @name
  @blurb "Elixir experiments, guides, and accompanying source code"
  @description "#{@blurb} for #{@homepage_url}."
  @blurb "#{@blurb}."
  @splash_image "#{@homepage_url}/splash.jpg"
  @authors ["Chris Keele"]

  @extras [
    "livebooks/conways-game-of-life.livemd": [
      filename: "conways-game-of-life",
      title: "Conway's Game of Life"
    ],
    "livebooks/surreal-numbers.livemd": [
      filename: "surreal-numbers",
      title: "Surreal Numbers"
    ]
  ]
  @groups_for_extras [
    Experiments: [
      "livebooks/conways-game-of-life.livemd",
      "livebooks/surreal-numbers.livemd"
    ]
  ]
  @groups_for_modules [
    # Livebooks: ~r/^Livebooks\./
  ]

  ####
  # Build stuff
  ##

  @env Mix.env()
  @target Mix.target()
  @dev_envs [:dev, :test]
  @doc_envs [:dev, :docs]

  # Capture module attributes to render EEx templates later
  @assigns Module.attributes_in(__MODULE__)
           |> Enum.map(&{&1, Module.get_attribute(__MODULE__, &1)})

  def project,
    do: [
      # Application
      app: @app,
      elixir: "~> 1.14",
      elixirc_options: [debug_info: Mix.env() in (@doc_envs ++ @dev_envs)],
      elixirc_paths: ["lib", "livebooks", "test"],
      start_permanent: Mix.env() == :prod,
      version: Version.to_string(@version),
      compilers: Mix.compilers() ++ [:livebooks],
      livebook_paths: ["livebooks"],
      # Informational
      name: @name,
      description: @description,
      source_url: @github_url,
      homepage_url: @homepage_url,
      # Configuration
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      dialyzer: dialyzer(),
      package: package(),
      test_coverage: test_coverage()
    ]

  def cli do
    test_tasks =
      [
        :check,
        :lint,
        :"lint.compile",
        :"lint.deps",
        :"lint.format",
        :"lint.style",
        :typecheck,
        :"typecheck.build-cache",
        :"typecheck.clean",
        :"typecheck.explain",
        :"typecheck.run",
        :"test.coverage",
        :"test.coverage.report"
      ]
      |> Map.new(&{&1, :test})

    doc_tasks = [:"site.build", :docs, :static] |> Map.new(&{&1, :docs})

    preferred_envs =
      %{}
      |> Map.merge(test_tasks)
      |> Map.merge(doc_tasks)
      |> Map.to_list()

    [
      default_env: :dev,
      preferred_envs: preferred_envs
    ]
  end

  def application() do
    [extra_application: [:logger], mod: {Livebooks, []}]
  end

  defp aliases,
    do: [
      ####
      # Developer tools
      ###

      # Build tasks
      build: [
        "site.build"
        # "hex.build" # IDK not always available
      ],

      # Build through ex_doc
      "site.build": ["docs", "static"],

      # Combination clean utility
      clean: [
        &clean_extra_folders/1,
        "typecheck.clean",
        &clean_build_folders/1
      ],

      # Installation tasks
      install: [
        "install.rebar",
        "install.hex",
        "install.deps"
      ],
      "install.rebar": "local.rebar --force",
      "install.hex": "local.hex --force",
      "install.deps": "deps.get",

      # Inject into ex_doc output
      static: &collect_static_assets/1,

      ####
      # Quality control tools
      ###

      # Check-all task
      check: [
        "test",
        "lint",
        "typecheck"
      ],

      # Linting tasks
      lint: [
        "lint.compile",
        "lint.deps",
        "lint.format",
        "lint.style"
      ],
      "lint.compile": "compile --force --warnings-as-errors",
      "lint.deps": "deps.unlock --check-unused",
      "lint.format": "format --check-formatted",
      "lint.style": "credo --strict",

      # Typecheck tasks
      typecheck: [
        "typecheck.run"
      ],
      "typecheck.build-cache": "dialyzer --plt --format dialyxir",
      "typecheck.clean": "dialyzer.clean",
      "typecheck.explain": "dialyzer.explain --format dialyxir",
      "typecheck.run": "dialyzer --format dialyxir",

      # Test tasks
      "test.coverage": "coveralls",
      "test.coverage.report": "coveralls.github"
    ]

  defp deps(),
    do: [
      {:matcha, "~> 0.1"},
      {:livebook, "~> 0.12", runtime: false},
      # Site generation
      {:ex_doc, "~> 0.30", only: @doc_envs, runtime: false},
      # Static analysis
      {:credo, "~> 1.7", only: @dev_envs, runtime: false},
      {:dialyxir, "~> 1.4", only: @dev_envs, runtime: false, override: true},
      {:excoveralls, "~> 0.18", only: :test}
    ]

  defp docs,
    do: [
      # Metadata
      name: @name,
      authors: @authors,
      source_ref: @github_branch,
      source_url: @github_url,
      homepage_url: @homepage_url,
      # Files and Layout
      output: "site",
      formatter: "html",
      main: "home",
      api_reference: false,
      extra_section: "LIVEBOOKS",
      logo: "images/logo.png",
      # cover: "images/livebooks.jpg",
      extras:
        @extras ++
          [
            "README.md": [filename: "home", title: "Home"],
            "LICENSE.md": [filename: "license", title: "License"]
          ],
      groups_for_modules: @groups_for_modules,
      groups_for_extras: @groups_for_extras,
      before_closing_head_tag: fn
        :epub ->
          ""

        :html ->
          EEx.eval_file("html/head.html.eex", assigns: @assigns)
      end,
      before_closing_body_tag: fn
        :epub ->
          ""

        :html ->
          EEx.eval_file("html/body.html.eex", assigns: @assigns)
      end,
      before_closing_footer_tag: fn
        :epub ->
          ""

        :html ->
          EEx.eval_file("html/footer.html.eex", assigns: @assigns)
      end
    ]

  defp dialyzer,
    do: [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      flags: ["-Wunmatched_returns", :error_handling, :underspecs],
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true,
      plt_add_apps: [],
      plt_ignore_apps: []
    ]

  defp package,
    do: [
      maintainers: @maintainers,
      licenses: @licenses,
      links: %{
        Home: @homepage_url,
        GitHub: @github_url
      },
      files: [
        "lib",
        "livebooks",
        "mix.exs",
        "LICENSE.md",
        "README.md",
        "VERSION"
      ]
    ]

  defp test_coverage do
    [
      tool: ExCoveralls
    ]
  end

  defp clean_build_folders(_) do
    ~w[_build deps] |> Enum.map(&File.rm_rf!/1)
  end

  defp clean_extra_folders(_) do
    ~w[cover doc] |> Enum.map(&File.rm_rf!/1)
  end

  defp collect_static_assets(_) do
    IO.puts("Adding static assets to site...")
    File.mkdir_p!("site")
    File.cp_r!("static", "site")
  end
end
