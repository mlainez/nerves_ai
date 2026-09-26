defmodule NervesAI.Application do
  @moduledoc false

  use Application
  require Logger

  # Boot tasks for the full Nerves AI stack:
  #
  #   1. Resize the F2FS data partition on first boot (idempotent,
  #      disabled unless `config :nerves_data_resize, :config` names a
  #      partition). Runs synchronously, before anything writes there.
  #   2. Wire `arm_ai`'s backends as the defaults for the generic
  #      libraries, unless a backend is already configured.
  #   3. Download the models in `config :nerves_ai, :models` in a
  #      supervised task that retries with backoff, so boot never waits
  #      on the network.
  @impl true
  def start(_type, _args) do
    children =
      case Application.get_env(:nerves_ai, :boot_mode, :normal) do
        :recovery ->
          Logger.warning("[nerves_ai] boot_mode :recovery — skipping resize, backends, and models")
          []

        _ ->
          run_storage_resize()
          wire_default_backends()
          model_children()
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: NervesAI.Supervisor)
  end

  defp run_storage_resize do
    _ = NervesDataResize.run()
  rescue
    e -> Logger.warning("[nerves_ai] storage resize crashed: #{Exception.message(e)}")
  end

  defp wire_default_backends do
    maybe_default(:nx_primitives, :backend, ArmAI.NxPrimitivesBackend)
    maybe_default(:infer_llm, :backend, ArmAI.LLMBackend)
    maybe_default(:infer_vision, :backend, ArmAI.VisionBackend)
    maybe_default(:infer_audio, :backend, ArmAI.AudioBackend)
  end

  defp maybe_default(app, key, default) do
    if Application.get_env(app, key) == nil do
      Application.put_env(app, key, default)
    end
  end

  defp model_children do
    case Application.get_env(:nerves_ai, :models, []) do
      [] -> []
      models -> [Supervisor.child_spec({Task, fn -> NervesAI.Models.fetch(models) end}, restart: :transient)]
    end
  end
end
