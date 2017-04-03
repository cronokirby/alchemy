defmodule Alchemy.Mixfile do
  use Mix.Project


  def project do
    [app: :alchemy,
     version: "0.2.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps(),
     docs: docs()]
  end


  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     applications: [:httpotion]]
  end


  defp deps do
    [{:httpotion, "~> 3.0.2"},
     {:earmark, "~> 0.1", only: :dev},
     {:websocket_client, "~> 1.2"},
     {:ex_doc, "~> 0.11", only: :dev},
     {:poison, "~> 3.0"}]
  end

  defp description do
    """
    A Discord wrapper / framework for elixir.

    This package intends to provide a solid foundation for interacting
    with the Discord API, as well as a very easy command and event hook system.
    """
  end

  defp docs do
    [main: "intro", extras: ["docs/Intro.md"]]
  end

  defp package do
    [name: :discord_alchemy,
     files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
     maintainers: ["Lúcás Meier"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/cronokirby/alchemy"}
    ]
  end
end
