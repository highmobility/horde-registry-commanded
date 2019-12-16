use Mix.Config

import_config "config.exs"

config :integration,
  children: [
    Integration.App,
    HordeRegistryCommanded.NodeListener
  ]
