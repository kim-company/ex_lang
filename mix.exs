defmodule ExLang.MixProject do
  use Mix.Project

  @github_url "https://github.com/kim-company/ex_lang"

  def project do
    [
      app: :ex_lang,
      version: "2.1.0",
      elixir: "~> 1.18.1",
      start_permanent: Mix.env() == :prod,
      name: "ExLang",
      description: description(),
      package: package(),
      deps: deps()
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
      {:ecto, "~> 3.12", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["KIM Keep In Mind"],
      files: ~w(lib priv mix.exs README.md LICENSE),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end

  defp description do
    """
    Library designed to parse and convert language and locale codes based on BCP47.
    """
  end
end
