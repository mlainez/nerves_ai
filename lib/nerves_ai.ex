defmodule NervesAI do
  @moduledoc """
  Edge-AI inference stack for Nerves devices on ARM CPUs.

  Meta-package — depending on it pulls every layer of the stack
  and wires `arm_ai`'s NEON-tuned backends as the defaults for the
  generic behaviour-driven libraries.

  ## Stack layout

  | Package | What it ships |
  |---|---|
  | `arm_ai` | Rust NIF + Nx-free APIs (`ArmAI.LlamaCandle`, `ArmAI.Phonemizer`) + the `*Backend` impls for the generic libraries |
  | `nx_arm` | `Nx.Backend` + `Nx.Defn.Compiler` for the NEON kernels |
  | `nx_primitives` | Generic API: `NxPrimitives.FFT` / `Embeddings` / `Quantized` / `QuantizedConv` (backend-driven; see `NxPrimitives.Backend`) |
  | `infer_llm` | Generic API: `InferLLM.Whisper`, `InferLLM.KVCache`, `InferLLM.Sampling`, `InferLLM.Primitives` (backend-driven; see `InferLLM.Backend`) |
  | `infer_vision` | Generic API: `InferVision.YOLO`, `OCR`, `Face`, `Onnx`, `Preprocess`, `Detection`, `Image`, `StableDiffusion` (see `InferVision.Backend`) |
  | `infer_audio` | Generic API: `InferAudio.SileroVAD`, `InferAudio.Piper`, `InferAudio.Decoder` (see `InferAudio.Backend`) |
  | `cpu_governor` | `CpuGovernor.Performance` (scoped governor) + `CpuGovernor.Topology` |
  | `nerves_model_hub` | `NervesModelHub.ensure_all/0` — first-boot HF / URL downloads |
  | `nerves_data_resize` | `NervesDataResize.run/0` — first-boot F2FS partition grow |

  ## Backend wiring

  `NervesAI.Application` runs at boot and sets the default
  backend for each generic library:

  | Config key                              | Default value |
  |---|---|
  | `config :nx_primitives, :backend, …`    | `ArmAI.NxPrimitivesBackend` |
  | `config :infer_llm, :backend, …`              | `ArmAI.LLMBackend` |
  | `config :infer_vision, :backend, …`           | `ArmAI.VisionBackend` |
  | `config :infer_audio, :backend, …`            | `ArmAI.AudioBackend` |

  Defaults are only applied when the key is unset, so any
  pre-existing config wins. To swap in a different backend
  (CUDA, AVX, Metal), set the same config key to your impl.

  ## When to use a smaller dep instead

  * **LLM-only, no Nx**: `{:arm_ai, "~> 0.1"}` — pure binary API
  * **Nx backend only** (Bumblebee / Axon / Defn on ARM):
    `{:nx_arm, "~> 0.2"}`
  * **Vision-only**: `{:infer_vision, "~> 0.1"}` + `{:arm_ai, "~> 0.1"}`
    — pulls `nx_arm`, `nx_primitives` transitively. You provide
    the `InferVision.Backend` config.

  ## Quick start

      defp deps do
        [{:nerves_ai, "~> 0.1"}]
      end

      Nx.global_default_backend(NxArm.Backend)
      _ = NervesModelHub.ensure_all()           # first-boot downloads
      _ = NervesDataResize.run()            # first-boot resize
      CpuGovernor.Performance.with_performance(fn ->
        {:ok, model} = ArmAI.LlamaCandle.load("/root/models/tinyllama.gguf")
        ArmAI.LlamaCandle.generate(model, prompt_tokens: [1, 2724], max_new: 32)
      end)
  """
end
