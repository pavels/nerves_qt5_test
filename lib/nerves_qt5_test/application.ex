defmodule NervesQt5Test.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    platform_init(target())
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesQt5Test.Supervisor]
    children =
      [
        # Children for all targets
        # Starts a worker by calling: NervesQt5Test.Worker.start_link(arg)
        # {NervesQt5Test.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: NervesQt5Test.Worker.start_link(arg)
      # {NervesQt5Test.Worker, arg},
    ]
  end

  def children(_target) do
    [
      {MuonTrap.Daemon, [:code.priv_dir(:nerves_qt5_test) |> Path.join("automotive"), [], [env: qt_env()] ]}
    ]
  end

  defp platform_init(:host), do: :ok

  defp platform_init(_target) do
    env = qt_env()
    cwd = "/root"

    File.ln_s("#{:code.priv_dir(:nerves_qt5_runtime)}/qt5-engine", "/root/qt5-engine")

    cmd("/root/qt5-engine/sbin/udevd", ["-d"], cwd, env)
    cmd("/root/qt5-engine/sbin/udevadm", ["trigger", "--type=subsystems", "--action=add"], cwd, env)
    cmd("/root/qt5-engine/sbin/udevadm", ["trigger", "--type=devices", "--action=add"], cwd, env)
    cmd("/root/qt5-engine/sbin/udevadm", ["settle", "--timeout=30"], cwd, env)
  end

  def target() do
    Application.get_env(:nerves_qt5_test, :target)
  end

  defp qt_env() do
    %{
      "LD_LIBRARY_PATH" => "/root/qt5-engine/lib:/root/qt5-engine/qt5/lib"
    }
  end

  defp cmd(exec, args, cwd, env) do
    opts = [
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true,
      cd: cwd,
      env: env
    ]

    {%IO.Stream{}, status} = System.cmd(find_executable(exec), args, opts)
    status
  end

  defp find_executable(exec) do
    System.find_executable(exec) ||
      Mix.raise("""
      "#{exec}" not found in the path. If you have set the MAKE environment variable,
      please make sure it is correct.
      """)
  end
end
