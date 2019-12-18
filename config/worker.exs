use Mix.Config

import_config "test.exs"

config :horde_registry_commanded,
  children: [
    Integration.App,
    HordeRegistryCommanded.NodeListener
  ]
