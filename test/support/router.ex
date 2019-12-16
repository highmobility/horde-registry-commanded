defmodule Integration.Router do
  @moduledoc false
  use Commanded.Commands.Router

  alias Integration.Aggregate
  alias Integration.Commands.{Create, Update, Delete}

  dispatch([Create, Update, Delete], to: Aggregate, identity: :uuid)
end
