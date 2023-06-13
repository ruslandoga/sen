defmodule BackendTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  defmodule Backend do
    def init(__MODULE__) do
      {:ok, fn info -> IO.inspect(info) end}
    end

    def handle_event({level, _group_leader, {Logger, message, timestamp, metadata}}, f) do
      f.(%{level: level, message: message, timestamp: timestamp, metadata: Map.new(metadata)})
      {:ok, f}
    end

    def handle_event(:flush, f), do: {:ok, f}

    def handle_call({:configure, config}, f) do
      {:ok, :ok, config[:log] || f}
    end

    def code_change(_old_vsn, f, _extra), do: {:ok, f}
    def terminate(_reason, _state), do: :ok
  end

  setup do
    Logger.add_backend(Backend)
    on_exit(fn -> Logger.remove_backend(Backend) end)
  end

  test "spawn error" do
    test = self()
    Logger.configure_backend(Backend, log: fn info -> send(test, {:info, info}) end)

    capture_log(fn ->
      spawn(fn ->
        Logger.metadata(a: :b)
        1 / 0
      end)

      assert_receive {:info, info}

      # %{
      #   level: :error,
      #   message: [
      #     "Process ",
      #     "#PID<0.237.0>",
      #     " raised an exception",
      #     10,
      #     "** (ArithmeticError) bad argument in arithmetic expression",
      #     ["\n    " |
      #      "test/backend_test.exs:40: anonymous fn/0 in BackendTest.\"test error\"/1"]
      #   ],
      #   metadata: %{
      #     crash_reason: {%ArithmeticError{
      #        message: "bad argument in arithmetic expression"
      #      },
      #      [
      #        {BackendTest, :"-test error/1-fun-1-", 0,
      #         [file: 'test/backend_test.exs', line: 40]}
      #      ]},
      #     erl_level: :error,
      #     error_logger: %{emulator: true, tag: :error},
      #     gl: #PID<0.64.0>,
      #     pid: #PID<0.237.0>,
      #     time: 1686649815420842
      #   },
      #   timestamp: {{2023, 6, 13}, {17, 50, 15, 420}}
      # }

      assert %{
               level: :error,
               metadata: %{
                 erl_level: :error,
                 crash_reason:
                   {%ArithmeticError{message: "bad argument in arithmetic expression"},
                    _stacktrace}
               }
             } = info
    end)
  end

  test "task error" do
    test = self()
    Logger.configure_backend(Backend, log: fn info -> send(test, {:info, info}) end)

    capture_log(fn ->
      Task.start(fn ->
        Logger.metadata(a: :b)
        1 / 0
      end)

      assert_receive {:info, info}

      # %{
      #   level: :error,
      #   message: [
      #     "Task #PID<0.237.0> started from #PID<0.233.0> terminating",
      #     [
      #       [10 | "** (ArithmeticError) bad argument in arithmetic expression"],
      #       ["\n    " |
      #        "test/backend_test.exs:39: anonymous fn/0 in BackendTest.\"test error\"/1"],
      #       ["\n    " |
      #        "(elixir 1.14.5) lib/task/supervised.ex:89: Task.Supervised.invoke_mfa/2"],
      #       ["\n    " |
      #        "(stdlib 4.3.1.1) proc_lib.erl:240: :proc_lib.init_p_do_apply/3"]
      #     ],
      #     "\nFunction: #Function<3.31718148/0 in BackendTest.\"test error\"/1>",
      #     "\n    Args: []"
      #   ],
      #   metadata: %{
      #     a: :b,
      #     callers: [#PID<0.233.0>],
      #     crash_reason: {%ArithmeticError{
      #        message: "bad argument in arithmetic expression"
      #      },
      #      [
      #        {BackendTest, :"-test error/1-fun-1-", 0,
      #         [file: 'test/backend_test.exs', line: 39]},
      #        {Task.Supervised, :invoke_mfa, 2,
      #         [file: 'lib/task/supervised.ex', line: 89]},
      #        {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 240]}
      #      ]},
      #     domain: [:otp, :elixir],
      #     erl_level: :error,
      #     error_logger: %{tag: :error_msg},
      #     gl: #PID<0.64.0>,
      #     pid: #PID<0.237.0>,
      #     report_cb: &Task.Supervised.format_report/1,
      #     time: 1686650087761859
      #   },
      #   timestamp: {{2023, 6, 13}, {17, 54, 47, 761}}
      # }
      assert %{
               level: :error,
               metadata: %{
                 a: :b,
                 erl_level: :error,
                 crash_reason:
                   {%ArithmeticError{message: "bad argument in arithmetic expression"},
                    _stacktrace},
                 domain: [:otp, :elixir]
               }
             } = info
    end)
  end
end
