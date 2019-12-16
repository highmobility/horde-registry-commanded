use Mix.Config

import_config "config.exs"

config :integration,
  children: [
    Integration.App,
    {Integration.DistributedSupervisor, name: Integration.DistributedSupervisor},
    {Integration.NodeListener, invoke: {Integration.DistributedSupervisor, :start_handlers, []}}
  ]
