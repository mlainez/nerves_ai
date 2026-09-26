defmodule NervesAI.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :nerves_ai,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "NervesAI",
      description:
        "Meta-package: full edge-AI inference stack for Nerves devices on ARM CPUs. Wires the generic libraries (`nx_primitives`, `infer_llm`, `infer_vision`, `infer_audio`) to `arm_ai`'s NEON-tuned backends.",
      package: package(),
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NervesAI.Application, []}
    ]
  end

  # Pulls every layer and wires arm_ai as the default backend for each
  # generic library at boot. None of these packages is on Hex yet; for a
  # smaller surface, depend on individual repos from github.com/mlainez.
  defp deps do
    [
      # Foundation
      {:arm_ai, github: "mlainez/arm_ai"},
      {:nx_arm, github: "mlainez/nx_arm"},
      # Generic Nx-tensor libraries (backend-pluggable)
      {:nx_primitives, github: "mlainez/nx_primitives"},
      {:infer_llm, github: "mlainez/infer_llm"},
      {:infer_vision, github: "mlainez/infer_vision"},
      {:infer_audio, github: "mlainez/infer_audio"},
      # Generic-Linux helpers used by the device-side stack
      {:cpu_governor, github: "mlainez/cpu_governor"},
      {:nerves_model_hub, github: "mlainez/nerves_model_hub"},
      {:nerves_data_resize, github: "mlainez/nerves_data_resize"}
    ]
  end

  defp package do
    [
      name: :nerves_ai,
      licenses: ["Apache-2.0"],
      files: ~w(lib mix.exs README.md LICENSE),
      links: %{"GitHub" => "https://github.com/mlainez/nerves_ai"}
    ]
  end
end
