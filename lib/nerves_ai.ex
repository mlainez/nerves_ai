defmodule NervesAI do
  @moduledoc """
  Edge-AI inference stack for Nerves devices on ARM CPUs.

  This is a **meta-package** — depending on it pulls every layer
  in one shot:

  | Package | What it ships |
  |---|---|
  | `arm_ai` | The Rust NIF + Nx-free APIs (`ArmAI.LlamaCandle`, `ArmAI.Phonemizer`) |
  | `nx_arm` | `Nx.Backend` + `Nx.Defn.Compiler` for the NEON kernels |
  | `arm_nx_primitives` | `ArmNxPrimitives.FFT` / `Embeddings` / `Quantized` / `QuantizedConv` |
  | `arm_llm` | `ArmLLM.WhisperCandle`, `KVCache`, `Sampling`, RMSNorm/RoPE Nx primitives |
  | `arm_vision` | `ArmVision.YOLO`, `OCR`, `Face`, `Onnx`, `Preprocess`, `Detection`, `Image`, `StableDiffusion` |
  | `arm_audio` | `ArmAudio.SileroVAD`, `Piper`, `Decoder` |
  | `cpu_governor` | `CpuGovernor.Performance` (scoped governor) + `CpuGovernor.Topology` |
  | `model_hub` | `ModelHub.ensure_all/0` — first-boot HF / URL downloads |
  | `fwup_data_resize` | `FwupDataResize.run/0` — first-boot F2FS partition grow |

  ## When to use a smaller dep instead

  Each package above is independently published and useful. If
  you don't need the whole stack, depend on just what you use —
  saves compile time + binary size:

  * **LLM-only, no Nx**: `{:arm_ai, "~> 0.1"}` — pure binary API
  * **Nx backend only** (Bumblebee / Axon / Defn on ARM):
    `{:nx_arm, "~> 0.2"}`
  * **Vision-only**: `{:arm_vision, "~> 0.1"}` (also pulls
    `nx_arm`, `arm_ai`, `arm_nx_primitives` transitively)

  ## Quick start

      defp deps do
        [{:nerves_ai, "~> 0.1"}]
      end

      Nx.global_default_backend(NxArm.Backend)
      _ = ModelHub.ensure_all()           # first-boot downloads
      _ = FwupDataResize.run()            # first-boot resize
      CpuGovernor.Performance.with_performance(fn ->
        {:ok, model} = ArmAI.LlamaCandle.load("/root/models/tinyllama.gguf")
        ArmAI.LlamaCandle.generate(model, prompt_tokens: [1, 2724], max_new: 32)
      end)
  """
end
