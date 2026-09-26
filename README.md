# nerves_ai

Edge-AI inference stack for Nerves devices on ARM CPUs.

Meta-package that pulls every layer of the stack and wires `arm_ai`'s
NEON-tuned backends as defaults for the generic behaviour-driven
libraries.

## ⚠️ Very early work — built for a workshop, not for production

This stack was written for the **Goatmire Elixir workshop** on running
Nerves on Fairphone 3 hardware, and that's the context to read it in. It
exists for tinkering and teaching.

It is **not an actively maintained project** (yet). There are no
stability guarantees and APIs will change without notice. Treat it as
something to hack on, not as a dependency to build a product on.

## What's in the stack

```
nerves_ai (this meta-package — boots default backends, fetches models)
│
├── Foundation
│   ├── arm_ai             — Rust NIF: NEON kernels, candle LLM + Whisper,
│   │                        tract ONNX, audio/image decode; ArmAI.LlamaCandle
│   └── nx_arm             — Nx.Backend + Nx.Defn.Compiler on arm_ai
│
├── Generic Nx-tensor libraries (behaviour-driven; backend-pluggable)
│   ├── nx_primitives      — FFT, embeddings, int8 matmul + conv
│   ├── infer_llm          — Whisper STT, KV cache, sampling, primitives
│   ├── infer_vision       — YOLO, generic ONNX (float inputs), preprocessing
│   └── infer_audio        — audio decode / resample / WAV
│
└── Generic-Linux helpers
    ├── cpu_governor       — scoped performance governor + big.LITTLE topology
    ├── nerves_model_hub   — first-boot HF / URL / file model downloader
    └── nerves_data_resize — first-boot F2FS data-partition grow
```

## What has been verified

Every repo's test suite passes on Erlang/OTP 29.1.1 and Elixir 1.20.4.
The opt-in `:models` tests also ran these paths end to end with real
models on an x86_64 host:

| Path | Model | Result |
|---|---|---|
| `ArmAI.LlamaCandle` | TinyLlama 1.1B Chat Q4_K_M | "The capital of France is Paris.", stops at EOS |
| `InferLLM.Whisper` | candle `whisper-tiny.en` q80 GGUF | Exact transcript of the JFK sample |
| `InferVision.YOLO` (V5) | Ultralytics YOLOv5n | 4 people and the bus in `bus.jpg`, 0.4 s |
| `InferVision.YOLO` (V8) | YOLOv8n | Same detections |
| `NervesModelHub` | Hugging Face LFS file | Follows the CDN redirect with verified TLS |

To run those tests yourself, put the files named at the top of each
`*_model_test.exs` in a directory and set `NERVES_AI_MODELS` to it.

The NIF has run on a Fairphone 3 (Snapdragon 632), where TinyLlama decodes
at about 4.7 tokens/s. The Whisper and ONNX fixes in this release have not
been re-run on that device, and a Nerves cross-build has not been re-run
with the new toolchain.

## How the backend pattern works

Each of `nx_primitives`, `infer_llm`, `infer_vision`, `infer_audio`
defines a `<Pkg>.Backend` behaviour. `arm_ai` provides
`ArmAI.NxPrimitivesBackend`, `ArmAI.LLMBackend`, `ArmAI.VisionBackend`
and `ArmAI.AudioBackend` as the ARM implementations.

When `nerves_ai` boots, it sets each library's `:backend` config key to
the matching `ArmAI.*Backend` unless another backend is already set.

## Install

None of the packages is on Hex yet:

```elixir
defp deps do
  [{:nerves_ai, github: "mlainez/nerves_ai"}]
end
```

The `arm_ai` NIF is compiled from source, so the build machine needs a
Rust toolchain. For Nerves targets, add the matching Rust target, for
example `rustup target add aarch64-unknown-linux-gnu`.

## Toolchain

Aligned with the official Nerves systems (`nerves_system_br` 1.35):
Erlang/OTP 29.1.1 and Elixir 1.20.4-otp-29. Every repo in the stack pins
these in `.tool-versions` and requires Elixir `~> 1.17`. The Nx libraries
are pinned to Nx `~> 0.12.0`: `NxArm.Compiler` is built on the Nx 0.12
evaluator and calls internals that Nx 0.13 removed.

## Configuration

```elixir
# Models to fetch at boot (NervesModelHub format). Downloads run in a
# background task and retry with backoff until they succeed.
config :nerves_ai,
  models: [
    tinyllama: [
      source: {:hf, "TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF", "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"},
      path: "/data/models/tinyllama.gguf"
    ],
    tinyllama_tokenizer: [
      source: {:hf, "TinyLlama/TinyLlama-1.1B-Chat-v1.0", "tokenizer.json"},
      path: "/data/models/tinyllama-tokenizer.json"
    ]
  ]

# Optional: grow a pre-built F2FS data partition on first boot.
config :nerves_data_resize, :config, partition: "/dev/mmcblk0p3", mount_point: "/data"

# Optional: skip all boot work (e.g. a recovery build).
config :nerves_ai, boot_mode: :recovery
```

## Usage

```elixir
if NervesAI.Models.ready?(:tinyllama) do
  {:ok, model} =
    ArmAI.LlamaCandle.load("/data/models/tinyllama.gguf",
      tokenizer: "/data/models/tinyllama-tokenizer.json")

  {reply, _stats} =
    ArmAI.LlamaCandle.generate(model,
      prompt: "<|user|>\nWhat is Elixir?</s>\n<|assistant|>\n",
      max_new: 64,
      stop_tokens: [2])
end

# Whisper speech-to-text (see infer_llm's README for the model files)
{:ok, whisper} =
  InferLLM.Whisper.load(
    model: "/data/models/whisper-tiny-en-q80.gguf",
    tokenizer: "/data/models/whisper-tokenizer.json",
    mel_filters: "/data/models/melfilters.bytes",
    config: "/data/models/whisper-config.json")

pcm = InferAudio.Decoder.load_for_whisper("/data/clip.wav")
{:ok, text} = InferLLM.Whisper.transcribe(whisper, pcm)

# YOLOv5 object detection
{:ok, yolo} = InferVision.YOLO.load("/data/models/yolov5n.onnx")
image = InferVision.Preprocess.load_for_classifier("/data/photo.jpg",
          size: {640, 640}, mean: {0.0, 0.0, 0.0}, std: {1.0, 1.0, 1.0})
detections = InferVision.YOLO.detect(yolo, image)
```

## Known limits

* ONNX models run through tract with float inputs only. Models that take
  integer inputs (token ids for text encoders, Silero VAD, Piper TTS)
  are not supported yet.
* `ArmAI.LlamaCandle` loads GGUF files with `llama.*` metadata only, and
  decodes greedily.
* Gated Hugging Face repos, which need an access token, can't be fetched.

## License

Apache-2.0.
