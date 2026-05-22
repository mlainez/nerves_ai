defmodule NervesAI.Application do
  @moduledoc false

  use Application

  @doc """
  Wires `arm_ai`'s NEON-tuned backends as the defaults for every
  generic library in the stack — `nx_primitives`, `llm`, `vision`,
  `audio`. Users who want a different backend can override by
  setting `:backend` in their own config before this app starts.
  """
  @impl true
  def start(_type, _args) do
    maybe_default(:nx_primitives, :backend, ArmAI.NxPrimitivesBackend)
    maybe_default(:infer_llm, :backend, ArmAI.LLMBackend)
    maybe_default(:infer_vision, :backend, ArmAI.VisionBackend)
    maybe_default(:infer_audio, :backend, ArmAI.AudioBackend)

    Supervisor.start_link([], strategy: :one_for_one, name: NervesAI.Supervisor)
  end

  defp maybe_default(app, key, default) do
    if Application.get_env(app, key) == nil do
      Application.put_env(app, key, default)
    end
  end
end
