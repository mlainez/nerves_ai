defmodule NervesAI.Application do
  @moduledoc false

  use Application
  require Logger

  @doc """
  Boot tasks for the full Nerves AI stack:

    1. Resize the F2FS data partition on first boot (idempotent —
       no-op after that).
    2. Download configured models via the model hub.
    3. Wire `arm_ai`'s NEON-tuned backends as the defaults for the
       generic libraries (`nx_primitives`, `infer_llm`, etc.).

  Step 3 is the only one specific to *this* meta-package. Steps 1
  and 2 live here because they're application-level (Nerves device)
  orchestration, not anything the `arm_ai` NIF should be involved
  in.

  Users who want a different backend can override the `:backend`
  config keys before this app starts; we only set defaults when
  no value is configured.
  """
  @impl true
  def start(_type, _args) do
    case Application.get_env(:nerves_ai, :boot_mode, :normal) do
      :recovery ->
        Logger.warning(
          "[nerves_ai] BOOT_MODE=:recovery — skipping resize, hub, and backend wiring"
        )

      _ ->
        run_storage_resize()
        ensure_models()
        wire_default_backends()
    end

    Supervisor.start_link([], strategy: :one_for_one, name: NervesAI.Supervisor)
  end

  defp run_storage_resize do
    _ = FwupDataResize.run()
  rescue
    e -> Logger.warning("[nerves_ai] storage resize crashed: #{Exception.message(e)}")
  end

  defp ensure_models do
    case Application.get_env(:nerves_ai, :models, []) do
      [] ->
        :no_models_configured

      models ->
        try do
          case ModelHub.ensure_all(app: :nerves_ai, models: models) do
            {:ok, paths} ->
              Logger.info("[nerves_ai] model hub: #{map_size(paths)} model(s) ready")
              {:ok, paths}

            {:error, errors} ->
              for {id, reason} <- errors do
                Logger.warning("[nerves_ai] model hub: #{id} failed: #{inspect(reason)}")
              end

              {:error, errors}
          end
        rescue
          e -> Logger.warning("[nerves_ai] model hub crashed: #{Exception.message(e)}")
        end
    end
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
end
