defmodule Alchemy.Mixfile do
  use Mix.Project


  def project do
    [app: :alchemy,
     version: "0.1.8",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end


  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     applications: [:httpotion] ]
  end


  defp deps do
    [{:httpotion, "~> 3.0.2"},
     {:earmark, "~> 0.1", only: :dev},
     {:websocket_client, "~> 1.2"},
     {:ex_doc, "~> 0.11", only: :dev},
     {:poison, "~> 3.0"}]
  end
end
