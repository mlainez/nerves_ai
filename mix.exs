defmodule NervesAI.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :nerves_ai,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "NervesAI",
      description:
        "Meta-package: the full edge-AI inference stack for Nerves devices on ARM CPUs",
      package: package(),
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  # Pulls every piece of the stack. Users typically depend on this
  # one package and get LLM + Whisper + YOLO + Silero VAD + Piper +
  # generic ONNX inference, the NEON Nx backend, the model hub for
  # first-boot downloads, CPU governor scoping, and F2FS resize.
  #
  # If you want a smaller surface, pick individual packages instead:
  #   {:arm_ai, "~> 0.1"}         # NIF + LlamaCandle (no Nx)
  #   {:nx_arm, "~> 0.2"}         # JUST the Nx.Backend
  #   {:arm_llm, "~> 0.1"}        # LLM + STT Nx wrappers
  #   {:arm_vision, "~> 0.1"}     # vision Nx wrappers
  #   {:arm_audio, "~> 0.1"}      # audio Nx wrappers
  #   {:cpu_governor, "~> 0.1"}   # governor scope + topology
  #   {:model_hub, "~> 0.1"}      # HF/URL model downloader
  #   {:fwup_data_resize, "~> 0.1"}  # first-boot F2FS resize
  defp deps do
    [
      # arm_ai builds its NIF via rustler_precompiled; rustler must
      # be visible at this package's compile time too.
      {:rustler, "~> 0.36", optional: true},
      {:rustler_precompiled, "~> 0.8"},
      # Foundation: the NIF + Nx backend
      {:arm_ai, path: "../arm_ai"},
      {:nx_arm, path: "../nx_arm"},
      # Domain packages
      {:arm_nx_primitives, path: "../arm_nx_primitives"},
      {:arm_llm, path: "../arm_llm"},
      {:arm_vision, path: "../arm_vision"},
      {:arm_audio, path: "../arm_audio"},
      # Generic-Linux helpers used by the device-side stack
      {:cpu_governor, path: "../cpu_governor"},
      {:model_hub, path: "../model_hub"},
      {:fwup_data_resize, path: "../fwup_data_resize"}
    ]
  end

  defp package do
    [
      name: :nerves_ai,
      licenses: ["Apache-2.0"],
      files: ~w(lib mix.exs README.md),
      links: %{"GitHub" => "https://github.com/marclainez/nerves_ai"}
    ]
  end
end
