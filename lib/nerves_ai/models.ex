defmodule NervesAI.Models do
  @moduledoc """
  Model downloads for `nerves_ai`.

  At boot, `NervesAI.Application` fetches every model listed in
  `config :nerves_ai, :models` (same format as `NervesModelHub`) in a
  background task. Failed downloads are retried with exponential backoff
  (5 s doubling up to 5 min) until every model is present, so a device
  that boots before its network is up still gets its models.

  Use `ready?/1` or `NervesModelHub.path/2` to check whether a model has
  landed before loading it.
  """

  require Logger

  @initial_backoff 5_000
  @max_backoff 300_000

  @doc """
  True when the model `id` from `config :nerves_ai, :models` is on disk.
  """
  @spec ready?(atom()) :: boolean()
  def ready?(id), do: match?({:ok, _}, NervesModelHub.path(id, app: :nerves_ai))

  @doc false
  def fetch(models, backoff \\ @initial_backoff) do
    case safe_ensure_all(models) do
      {:ok, paths} ->
        Logger.info("[nerves_ai] #{map_size(paths)} model(s) ready")
        :ok

      {:error, errors} ->
        for {id, reason} <- errors do
          Logger.warning("[nerves_ai] model #{id} failed: #{inspect(reason)}; retrying in #{div(backoff, 1000)} s")
        end

        failed = Keyword.take(models, Enum.map(errors, &elem(&1, 0)))
        failed = if failed == [], do: models, else: failed
        Process.sleep(backoff)
        fetch(failed, min(backoff * 2, @max_backoff))
    end
  end

  defp safe_ensure_all(models) do
    NervesModelHub.ensure_all(models: models)
  rescue
    e -> {:error, Enum.map(models, fn {id, _} -> {id, {:exception, Exception.message(e)}} end)}
  end
end
