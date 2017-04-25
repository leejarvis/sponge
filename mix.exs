defmodule Sponge.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sponge,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps(),
      package: package(),
      name: "Sponge",
      description: description(),
      source_url: "https://github.com/leejarvis/sponge"
    ]
  end

  defp description do
    """
    Sponge is a library for dealing with building SOAP requests and parsing
    responses.
    """
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      name: :sponge,
      maintainers: ["Lee Jarvis"],
      files: ["lib", "README.md", "mix.exs", "LICENSE"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/leejarvis/sponge"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]
end
