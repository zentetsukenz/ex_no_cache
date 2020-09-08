defmodule ExNoCache.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_no_cache,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "ExNoCache is a plug for serving HTTP no-cache",
      source_url: "https://github.com/zentetsukenz/ex_no_cache/",
      homepage_url: "https://github.com/zentetsukenz/ex_no_cache",
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExNoCache.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, ">= 1.10.0 and < 2.0.0"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/zentetsukenz/ex_no_cache"
      },
      maintainers: ["Wiwatta Mongkhonchit"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      authors: ["Wiwatta Mongkhonchit"]
    ]
  end
end
