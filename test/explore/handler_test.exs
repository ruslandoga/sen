defmodule HandlerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  defmodule Handler do
    # %{
    #   filter_default: :log,
    #   filters: [],
    #   formatter: {:logger_formatter, %{}},
    #   id: :errors,
    #   level: :all,
    #   log: #Function<0.28597000/1 in HandlerTest.__ex_unit_setup_0/1>,
    #   module: HandlerTest.Handler
    # }
    def adding_handler(config) do
      {:ok, config}
    end

    def log(event, config) do
      config.log.(event)
    end
  end

  setup do
    test = self()
    :ok = :logger.add_handler(:errors, Handler, %{log: fn info -> send(test, {:info, info}) end})
    on_exit(fn -> :ok = :logger.remove_handler(:errors) end)
  end

  test "spawn error" do
    capture_log(fn ->
      spawn(fn ->
        Logger.metadata(a: :b)
        1 / 0
      end)

      assert_receive {:info, info}

      # %{
      #   level: :error,
      #   meta: %{error_logger: %{emulator: true, tag: :error}, gl: #PID<0.64.0>, pid: #PID<0.237.0>, time: 1686651508138611},
      #   msg: {'Error in process ~p with exit value:~n~p~n', [#PID<0.237.0>, {:badarith, [{HandlerTest, :"-test spawn error/1-fun-0-", 0, [file: 'test/handler_test.exs', line: 34]}]}]}
      # }
      assert %{
               level: :error,
               meta: %{error_logger: %{emulator: true, tag: :error}, gl: _, pid: _, time: _},
               msg: {'Error in process ~p with exit value:~n~p~n', [_, {:badarith, _}]}
             } = info
    end)
  end

  test "task error" do
    capture_log(fn ->
      Task.start(fn ->
        Logger.metadata(a: :b)
        1 / 0
      end)

      assert_receive {:info, info}

      # %{
      #   level: :error,
      #   meta: %{a: :b, callers: [#PID<0.233.0>], domain: [:otp, :elixir], error_logger: %{tag: :error_msg}, gl: #PID<0.64.0>, pid: #PID<0.237.0>, report_cb: &Task.Supervised.format_report/1, time: 1686651612104719},
      #   msg: {:report, %{label: {Task.Supervisor, :terminating}, report: %{args: [], function: #Function<4.34597173/0 in HandlerTest."test task error"/1>, name: #PID<0.237.0>, reason: {:badarith, [{HandlerTest, :"-test task error/1-fun-0-", 0, [file: 'test/handler_test.exs', line: 56]}, {Task.Supervised, :invoke_mfa, 2, [file: 'lib/task/supervised.ex', line: 89]}, {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 240]}]}, starter: #PID<0.233.0>}}}
      # }
      assert %{
               level: :error,
               meta: %{
                 a: :b,
                 domain: [:otp, :elixir]
               }
             } = info
    end)
  end
end
