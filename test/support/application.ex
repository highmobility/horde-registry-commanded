defmodule Integration.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      [
        # Starts a worker by calling: Integration.Worker.start_link(arg)
        # {Integration.Worker, arg}
      ] ++ (Application.get_env(:horde_registry_commanded, :children) || [])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Integration.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
