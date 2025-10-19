defmodule Tikentoken.MixProject do
  use Mix.Project

  def project do
    [
      app: :tikentoken,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Tikentoken.CLI],
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/florinpatrascu/tikentoken",
      docs: docs()
    ]
  end

  defp description do
    "Tikentoken is an Elixir library and CLI tool designed for experimentation and learning by tokenizing text with various Ollama models (supporting multiple modes for different tasks)."
  end

  defp package do
    [
      licenses: ["Affero GPLv3"],
      links: %{"GitHub" => "https://github.com/florinpatrascu/tikentoken"}
    ]
  end

  defp docs do
    [
      main: "Tikentoken",
      extras: ["README.md", "INTEGRATION.md"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5.15"}
    ]
  end
end
