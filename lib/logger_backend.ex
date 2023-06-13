defmodule Sen.LoggerBackends.Sentry do
  @moduledoc """
  A logger backend that sends errors to Sentry.
  """

  @behaviour :gen_event

  @impl true
  def init(__MODULE__) do
    opts = Application.fetch_env!(:logger, __MODULE__)
    init({__MODULE__, opts})
  end

  def init({__MODULE__, opts}) do
    dsn = Keyword.fetch!(opts, :dsn)
    name = opts[:name] || __MODULE__.Finch
    level = opts[:level] || :error
    metadata = opts[:metadata] || :all

    %URI{userinfo: userinfo} = uri = URI.parse(dsn)
    url = URI.to_string(%URI{uri | userinfo: nil})
    config = %{name: name, url: url, userinfo: userinfo, level: level, metadata: metadata}

    # TODO consider http2
    # TODO where should finch be started?
    with {:ok, _} <- Finch.start_link(name: name, pools: %{url => []}) do
      {:ok, config}
    end
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

  defp build_envelop(level, msg, datetime, metadata, _config) do
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

  defp send_envelop(_config, _envelop) do
    :ok
  end
end
