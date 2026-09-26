defmodule NervesAITest do
  use ExUnit.Case, async: false

  test "the application wires the arm_ai backends at boot" do
    assert Application.get_env(:nx_primitives, :backend) == ArmAI.NxPrimitivesBackend
    assert Application.get_env(:infer_llm, :backend) == ArmAI.LLMBackend
    assert Application.get_env(:infer_vision, :backend) == ArmAI.VisionBackend
    assert Application.get_env(:infer_audio, :backend) == ArmAI.AudioBackend
    assert is_pid(Process.whereis(NervesAI.Supervisor))
  end

  test "every wired backend implements its behaviour's callbacks" do
    for {backend, behaviour} <- [
          {ArmAI.NxPrimitivesBackend, NxPrimitives.Backend},
          {ArmAI.LLMBackend, InferLLM.Backend},
          {ArmAI.VisionBackend, InferVision.Backend},
          {ArmAI.AudioBackend, InferAudio.Backend}
        ] do
      Code.ensure_loaded!(backend)

      for {fun, arity} <- behaviour.behaviour_info(:callbacks) do
        assert function_exported?(backend, fun, arity),
               "#{inspect(backend)} is missing #{fun}/#{arity} from #{inspect(behaviour)}"
      end
    end
  end

  describe "NervesAI.Models" do
    @describetag :tmp_dir

    test "fetch/1 stages models and ready?/1 sees them", %{tmp_dir: dir} do
      src = Path.join(dir, "src.bin")
      File.write!(src, "weights")
      dest = Path.join(dir, "models/m.bin")
      models = [m: [source: {:file, src}, path: dest]]

      Application.put_env(:nerves_ai, :models, models)
      on_exit(fn -> Application.delete_env(:nerves_ai, :models) end)

      refute NervesAI.Models.ready?(:m)
      assert :ok = NervesAI.Models.fetch(models)
      assert NervesAI.Models.ready?(:m)
      assert File.read!(dest) == "weights"
    end

    test "fetch/2 retries a failed model until it succeeds", %{tmp_dir: dir} do
      src = Path.join(dir, "late.bin")
      dest = Path.join(dir, "late_out.bin")
      models = [late: [source: {:file, src}, path: dest]]

      task = Task.async(fn -> NervesAI.Models.fetch(models, 50) end)
      Process.sleep(120)
      File.write!(src, "arrived")

      assert :ok = Task.await(task, 2_000)
      assert File.read!(dest) == "arrived"
    end
  end
end
