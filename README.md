# nerves_ai

Edge-AI inference stack for Nerves devices on ARM CPUs.

Meta-package that pulls every layer of the stack and wires
`arm_ai`'s NEON-tuned backends as defaults for the generic
behaviour-driven libraries.

## What's in the stack

```
nerves_ai (this meta-package — boots default backends)
│
├── Foundation
│   ├── arm_ai             — NIF + Nx-free APIs (LlamaCandle, Phonemizer)
│   └── nx_arm             — JUST Nx.Backend + Nx.Defn.Compiler
│
├── Generic Nx-tensor libraries (behaviour-driven; backend-pluggable)
│   ├── nx_primitives      — FFT, embeddings, quantized helpers
│   ├── llm                — Whisper STT, KV cache, sampling, LLM primitives
│   ├── vision             — YOLO, OCR, Face, ONNX, vision preprocess
│   └── audio              — Silero VAD, Piper TTS, audio decode/resample
│
└── Generic-Linux helpers
    ├── cpu_governor       — scoped governor + big.LITTLE topology
    ├── model_hub          — first-boot HF/URL model downloader
    └── fwup_data_resize   — first-boot F2FS data-partition grow
```

## How the backend pattern works

Each of `nx_primitives`, `llm`, `vision`, `audio` defines a
`<Pkg>.Backend` behaviour. `arm_ai` provides
`ArmAI.NxPrimitivesBackend`, `ArmAI.LLMBackend`,
`ArmAI.VisionBackend`, `ArmAI.AudioBackend` as the ARM-NEON
implementations.

When `nerves_ai` boots, it sets each library's `:backend` config
key to the matching `ArmAI.*Backend` (if no other choice is
already set). Future alternative backends (CUDA, AVX, Metal) slot
in by implementing the same behaviour and pointing the config
at them.

## Install

```elixir
defp deps do
  [{:nerves_ai, "~> 0.1"}]
end
```

## Usage

```elixir
# Set the NEON Nx backend as default so Bumblebee / Axon use it
Nx.global_default_backend(NxArm.Backend)

# At boot:
_ = ModelHub.ensure_all()      # download configured models
_ = FwupDataResize.run()       # grow /root partition (once)

# Run an LLM burst at the perf governor
CpuGovernor.Performance.with_performance(fn ->
  {:ok, model} = ArmAI.LlamaCandle.load("/root/models/tinyllama.gguf")
  ArmAI.LlamaCandle.generate(model, prompt_tokens: [1, 2724], max_new: 32)
end)

# Whisper STT — uses the configured InferLLM.Backend (= ArmAI.LLMBackend)
{:ok, whisper} = InferLLM.Whisper.load(
  model: "/root/whisper-tiny.gguf",
  tokenizer: "/root/whisper-tokenizer.json",
  mel_filters: "/root/mel_filters.bin",
  config: "/root/whisper-config.json"
)
pcm = InferAudio.Decoder.load_for_whisper("/root/clip.mp3")
{:ok, transcript} = InferLLM.Whisper.transcribe(whisper, pcm)
```

## Smaller deps

If you don't need the full stack, depend on individual packages
instead:

* `arm_ai` alone — NIF + LlamaCandle (no Nx)
* `nx_arm` alone — Nx.Backend for Bumblebee/Axon
* `vision` + `arm_ai` — YOLO/OCR/Face wrappers with the ARM backend
* `llm` + `arm_ai` — Whisper + LLM primitives with the ARM backend

See each package's mix.exs and README for its own dependency story.

## License

Apache-2.0.
