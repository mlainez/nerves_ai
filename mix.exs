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

  # Pulls every layer + wires arm_ai as the default backend for each
  # generic library at boot time.
  #
  # If you want a smaller surface, pick individual packages instead:
  #
  #   {:arm_ai, "~> 0.1"}         # NIF + LlamaCandle (no Nx)
  #   {:nx_arm, "~> 0.2"}         # JUST the Nx.Backend
  #   {:nx_primitives, "~> 0.1"}  # FFT / embeddings / quantized
  #   {:infer_llm, "~> 0.1"}            # Whisper + LLM Nx wrappers
  #   {:infer_vision, "~> 0.1"}         # YOLO / OCR / Face / ONNX wrappers
  #   {:infer_audio, "~> 0.1"}          # Silero VAD / Piper / audio I/O
  #   {:cpu_governor, "~> 0.1"}   # governor scope + topology
  #   {:nerves_model_hub, "~> 0.1"}      # HF/URL model downloader
  #   {:nerves_data_resize, "~> 0.1"}  # first-boot F2FS resize
  defp deps do
    [
      # arm_ai builds its NIF via rustler_precompiled; rustler must
      # be visible at this package's compile time too.
      {:rustler, "~> 0.36", optional: true},
      {:rustler_precompiled, "~> 0.8"},
      # Foundation
      {:arm_ai, path: "../arm_ai"},
      {:nx_arm, path: "../nx_arm"},
      # Generic Nx-tensor libraries (backend-pluggable)
      {:nx_primitives, path: "../nx_primitives"},
      {:infer_llm, path: "../infer_llm"},
      {:infer_vision, path: "../infer_vision"},
      {:infer_audio, path: "../infer_audio"},
      # Generic-Linux helpers used by the device-side stack
      {:cpu_governor, path: "../cpu_governor"},
      {:nerves_model_hub, path: "../nerves_model_hub"},
      {:nerves_data_resize, path: "../nerves_data_resize"}
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
