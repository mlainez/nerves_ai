# nerves_ai

Edge-AI inference stack for Nerves devices on ARM CPUs.

Meta-package that pulls every layer of the stack and wires
`arm_ai`'s NEON-tuned backends as defaults for the generic
behaviour-driven libraries.

## ⚠️ Very early work — built for a workshop, not for production

This stack was written for the **Goatmire Elixir workshop** on running
Nerves on Fairphone 3 hardware, and that's the context to read it in. It
exists for tinkering and teaching.

It is **not an actively maintained project** (yet). There are no
stability guarantees, APIs will change without notice, and several parts
are wired-but-unproven — the per-package READMEs say which. Treat it as
something to hack on, not as a dependency to build a product on.

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
│   ├── infer_llm          — Whisper STT, KV cache, sampling, LLM primitives
│   ├── infer_vision       — YOLO, OCR, Face, ONNX, vision preprocess
│   └── infer_audio        — Silero VAD, Piper TTS, audio decode/resample
│
└── Generic-Linux helpers
    ├── cpu_governor       — scoped governor + big.LITTLE topology
    ├── nerves_model_hub   — first-boot HF/URL model downloader
    └── nerves_data_resize — first-boot F2FS data-partition grow
```

## How the backend pattern works

Each of `nx_primitives`, `infer_llm`, `infer_vision`, `infer_audio`
defines a `<Pkg>.Backend` behaviour. `arm_ai` provides
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
_ = NervesModelHub.ensure_all()      # download configured models
_ = NervesDataResize.run()       # grow /root partition (once)

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
* `infer_vision` + `arm_ai` — YOLO/OCR/Face wrappers with the ARM backend
* `infer_llm` + `arm_ai` — Whisper + LLM primitives with the ARM backend

See each package's mix.exs and README for its own dependency story.

## License

Apache-2.0.
