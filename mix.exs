defmodule Livebook.MixProject do
  use Mix.Project

  @app :livebook
  @name "Chris Keele's Livebooks"
  @maintainers ["Chris Keele"]
  @licenses ["MIT"]

  @homepage_domain "livebooks.chriskeele.com"
  @homepage_url "https://#{@homepage_domain}"
  @github_url "https://github.com/christhekeele/livebooks"
  @github_branch "latest"

  @title @name
  @blurb "Elixir experiments, guides, and accompanying source code"
  @description "#{@blurb} for #{@homepage_url}."
  @blurb "#{@blurb}."
  @splash_image "#{@homepage_url}/splash.jpg"
  @authors ["Chris Keele"]

  @extras [
    "livebooks/life.livemd": [
      filename: "game-of-life",
      title: "Conway's Game of Life"
    ],
    "livebooks/surreal.livemd": [
      filename: "surreal-numbers",
      title: "Surreal Numbers"
    ]
  ]
  @groups_for_extras [
    Experiments: [
      "livebooks/life.livemd",
      "livebooks/surreal.livemd"
    ]
  ]
  @groups_for_modules [
    # Livebooks: ~r/^Livebooks\./
  ]

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
    [extra_application: [:logger], mod: {Livebook, []}]
  end

  defp aliases,
    do: [
      ####
      # Developer tools
      ###

      # Build tasks
      build: ["site.build", "hex.build"],

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
      # Site generation
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
      # cover: "images/livebooks.jpg",
      extras:
        @extras ++
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

          .sidebar .sidebar-projectVersion {
            display: none;
          }

          .content-inner pre code {
            font-family: Menlo, Courier, monospace !important;
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

        <meta name="description" content="#{@title}: #{@blurb}" />

        <!-- Facebook Meta Tags -->
        <meta
          name="og:url"
          property="og:url"
          content="#{@homepage_url}"
        />
        <meta
          name="og:type"
          property="og:type"
          content="website"
        />
        <meta
          name="og:title"
          property="og:title"
          content="#{@title}"
        />
        <meta
          name="og:description"
          property="og:description"
          content="#{@blurb}"
        />
        <meta
          name="og:image"
          property="og:image"
          content="#{@splash_image}"
        />

        <!-- Twitter Meta Tags -->
        <meta
          name="twitter:card"
          property="twitter:card"
          content="summary_large_image"
        />
        <meta
          name="twitter:domain"
          property="twitter:domain"
          content="#{@homepage_domain}"
        />
        <meta
          name="twitter:url"
          property="twitter:url"
          content="#{@homepage_url}"
        />
        <meta
          name="twitter:title"
          property="twitter:title"
          content="#{@title}"
        />
        <meta
          name="twitter:description"
          property="twitter:description"
          content="#{@blurb}"
        />
        <meta
          name="twitter:image"
          property="twitter:image"
          content="#{@splash_image}"
        />
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
