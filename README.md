# nerves_ai

Edge-AI inference stack for Nerves devices on ARM CPUs. Meta-package
pulling every layer of the stack in one shot.

## What's in the stack

```
nerves_ai (this meta-package)
├── arm_ai             — NIF + Nx-free APIs (LlamaCandle, Phonemizer)
├── nx_arm             — JUST Nx.Backend + Nx.Defn.Compiler
├── arm_nx_primitives  — FFT, embeddings, quantized helpers
├── arm_llm            — Whisper STT, KV cache, sampling, LLM primitives
├── arm_vision         — YOLO, OCR, Face, ONNX, vision preprocess
├── arm_audio          — Silero VAD, Piper TTS, audio decode/resample
├── cpu_governor       — scoped governor + big.LITTLE topology
├── model_hub          — first-boot HF/URL model downloader
└── fwup_data_resize   — first-boot F2FS data-partition grow
```

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
```

## Smaller deps

If you don't need the full stack, depend on individual packages
instead — see `lib/nerves_ai.ex` for the per-package breakdown.

## License

Apache-2.0.
