defmodule Livebooks.MixProject do
  use Mix.Project

  @app :livebooks
  @name "Chris Keele's Livebooks"

  @livebooks [
    "livebooks/life.livemd": [
      filename: "game-of-life",
      title: "Conway's Game of Life"
    ]
  ]
  @groups_for_extras [
    Experiments: [
      "livebooks/life.livemd"
    ]
  ]
  @groups_for_modules [
    # Livebooks: ~r/^Livebooks\./
  ]

  @homepage_url "https://livebooks.chriskeele.com"
  @github_url "https://github.com/christhekeele/livebooks"
  @github_branch "latest"

  @description "My livebooks and supporting code for #{@homepage_url}."
  @authors ["Chris Keele"]
  @maintainers ["Chris Keele"]
  @licenses ["MIT"]

  @dev_envs [:dev, :test]
  @doc_envs [:dev, :docs]

  @version "VERSION" |> File.read!() |> String.trim() |> Version.parse!()

  def project,
    do: [
      # Application
      app: @app,
      elixir: "~> 1.14",
      elixirc_options: [debug_info: Mix.env() in (@doc_envs ++ @dev_envs)],
      start_permanent: Mix.env() == :prod,
      version: Version.to_string(@version),
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
    test_by_default = aliases() |> Keyword.keys() |> Map.new(&{&1, :test})
    doc_overrides = [:build, :docs, :static] |> Map.new(&{&1, :docs})

    preferred_envs =
      test_by_default
      |> Map.merge(doc_overrides)
      |> Map.to_list()

    [
      default_task: "docs",
      preferred_envs: preferred_envs
    ]
  end

  def application(),
    do: [
      extra_application: [:logger]
    ]

  defp aliases,
    do: [
      ####
      # Developer tools
      ###

      # Build through ex_doc
      build: ["docs"],

      # Combination clean utility
      clean: [
        &clean_extra_folders/1,
        "typecheck.clean",
        &clean_build_folders/1
      ],

      # Ensure hex.publish also adds static files
      docs: ["docs", "static"],

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
      {:ex_doc, "~> 0.32", only: @doc_envs, runtime: false},
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
      # cover: "docs/img/cover.png",
      extras:
        @livebooks ++
          [
            "README.md": [filename: "home", title: "Home"],
            "LICENSE.md": [filename: "license", title: "License"]
          ],
      groups_for_modules: @groups_for_modules,
      groups_for_extras: @groups_for_extras,
      before_closing_head_tag: fn _ ->
        """
        <style>
          .sidebar .sidebar-projectImage img {
            border-radius: 100%;
            max-width: 64px;
            max-height: 64px;
          }
        </style>

        <link rel="apple-touch-icon" sizes="57x57" href="/apple-icon-57x57.png">
        <link rel="apple-touch-icon" sizes="60x60" href="/apple-icon-60x60.png">
        <link rel="apple-touch-icon" sizes="72x72" href="/apple-icon-72x72.png">
        <link rel="apple-touch-icon" sizes="76x76" href="/apple-icon-76x76.png">
        <link rel="apple-touch-icon" sizes="114x114" href="/apple-icon-114x114.png">
        <link rel="apple-touch-icon" sizes="120x120" href="/apple-icon-120x120.png">
        <link rel="apple-touch-icon" sizes="144x144" href="/apple-icon-144x144.png">
        <link rel="apple-touch-icon" sizes="152x152" href="/apple-icon-152x152.png">
        <link rel="apple-touch-icon" sizes="180x180" href="/apple-icon-180x180.png">
        <link rel="icon" type="image/png" sizes="192x192"  href="/android-icon-192x192.png">
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
        <link rel="icon" type="image/png" sizes="96x96" href="/favicon-96x96.png">
        <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
        <link rel="shortcut icon" href="favicon.ico">
        <link rel="manifest" href="/manifest.json">
        <meta name="msapplication-TileColor" content="#6932a8">
        <meta name="msapplication-TileImage" content="/ms-icon-144x144.png">
        <meta name="theme-color" content="#6932a8">
        """
      end,
      before_closing_body_tag: fn _ ->
        """
        <script>
        document.getElementById("modules-list-tab-button").innerHTML = "Supporting Code";
        </script>
        """
      end,
      before_closing_footer_tag: fn _ ->
        """
        <script>
        document.getElementsByTagName('footer')[0].children[0].remove();
        </script>
        """
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
