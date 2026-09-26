defmodule NervesAI do
  @moduledoc """
  Edge-AI inference stack for Nerves devices on ARM CPUs.

  Meta-package: depending on it pulls every layer of the stack. At boot,
  `NervesAI.Application`:

    1. grows a pre-built F2FS data partition if
       `config :nerves_data_resize, :config` names one;
    2. wires `arm_ai`'s backends as the defaults for the generic
       libraries (only where no backend is configured):

       | Config key                           | Default                     |
       |---|---|
       | `config :nx_primitives, :backend`    | `ArmAI.NxPrimitivesBackend` |
       | `config :infer_llm, :backend`        | `ArmAI.LLMBackend`          |
       | `config :infer_vision, :backend`     | `ArmAI.VisionBackend`       |
       | `config :infer_audio, :backend`      | `ArmAI.AudioBackend`        |

    3. fetches `config :nerves_ai, :models` in a background task that
       retries with backoff (see `NervesAI.Models`).

  Set `config :nerves_ai, boot_mode: :recovery` to skip all three.

  ## Stack layout

  | Package | What it ships |
  |---|---|
  | `arm_ai` | Rust NIF, `ArmAI.LlamaCandle`, and the `ArmAI.*Backend` implementations |
  | `nx_arm` | `NxArm.Backend` (`Nx.Backend`) and `NxArm.Compiler` (`Nx.Defn.Compiler`) |
  | `nx_primitives` | `NxPrimitives.FFT`, `Embeddings`, `Quantized`, `QuantizedConv` |
  | `infer_llm` | `InferLLM.Whisper`, `KVCache`, `Sampling`, `Primitives` |
  | `infer_vision` | `InferVision.YOLO`, `Onnx`, `Preprocess`, `Image`, `Detection` |
  | `infer_audio` | `InferAudio.Decoder` |
  | `cpu_governor` | `CpuGovernor.Performance` and `CpuGovernor.Topology` |
  | `nerves_model_hub` | `NervesModelHub` — HF / URL / file model downloads |
  | `nerves_data_resize` | `NervesDataResize` — first-boot F2FS grow |
  """
end
