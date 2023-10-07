defmodule Sen do
  @moduledoc """
  A minimal Sentry client and a `Logger` backend.
  """

  @doc """
  To capture an exception manually.
  """
  def capture_exception(exception, opts \\ []) do
  end

  @behaviour :gen_event

  @impl true
  def init(__MODULE__) do
    opts = Application.fetch_env!(:logger, __MODULE__)

    dsn = Keyword.fetch!(opts, :dsn)

    finch_name =
      case Keyword.get(opts, :finch_name) do
        nil ->
          {:ok, pid} = Finch.start_link([])
          pid

        name when is_atom(name) ->
          name
      end

    level = Keyword.fetch!(opts, :level)
    metadata = Keyword.fetch!(opts, :metadata)

    %URI{userinfo: userinfo} = uri = URI.parse(dsn)
    url = URI.to_string(%URI{uri | userinfo: nil})

    config = %{
      finch_name: finch_name,
      url: url,
      userinfo: userinfo,
      level: level,
      metadata: metadata
    }

    {:ok, config}
  end

  @impl true
  def handle_event({_level, group_leader, _info}, config) when node(group_leader) != node() do
    {:ok, config}
  end

  def handle_event({level, _group_leader, {Logger, message, timestamp, metadata}}, config) do
    # TODO for level use erl_level
    case Logger.compare_levels(level, config.level) do
      compared when compared in [:gt, :eq] ->
        send_envelop(config, build_envelop(level, message, timestamp, metadata, config))
        {:ok, config}

      _ ->
        {:ok, config}
    end
  end

  def handle_event(:flush, config) do
    {:ok, config}
  end

  @impl true
  def handle_call({:configure, opts}, config) do
    config = Map.put(config, :level, opts[:level] || config.level)
    config = Map.put(config, :metadata, opts[:metadata] || config.metadata)
    {:ok, :ok, config}
  end

  @impl true
  def code_change(_old_vsn, config, _extra), do: {:ok, config}

  @impl true
  def terminate(_reason, _state), do: :ok

  defp build_event(level, msg, datetime, metadata, _config) do
    level =
      case level do
        _ when level in [:emergency, :alert, :critical] -> "fatal"
        :error -> "error"
        _ when level in [:warning, :warn] -> "warning"
        _ when level in [:notice, :info] -> "info"
        :debug -> "debug"
      end

    IO.inspect(level: level, msg: msg, datetime: datetime, metadata: metadata)
  end

  defp send_event(config, event) do
    %{finch_name: finch_name, url: url, userinfo: userinfo} = config
    body = Jason.encode_to_iodata!(event)

    headers = [
      {"authorization", "Basic #{userinfo}"},
      {"content-type", "application/json"},
      {"user-agent", "sen-elixir/0.1.0"}
    ]

    case Finch.build("POST", Path.join(url, "/api/store"), headers, body) do
      {:ok, %Finch.Response{status: 200}} -> :ok
      {:ok, %Finch.Response{} = resp} -> {:error, resp}
      {:error, _reason} = error -> error
    end
  end
end
