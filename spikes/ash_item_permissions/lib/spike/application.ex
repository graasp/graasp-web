defmodule Spike.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    Supervisor.start_link([Spike.Repo], strategy: :one_for_one, name: Spike.Supervisor)
  end
end
