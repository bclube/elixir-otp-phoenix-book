defmodule IslandsEngine.GameSupervisor do
  use Supervisor

  alias IslandsEngine.Game

  def start_link(_options), do:
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc "Starts a game. `name` is player 1's name"
  def start_game(name), do:
    Supervisor.start_child(__MODULE__, [name])

  @doc "Stops the game with the given `name`."
  def stop_game(name), do:
    Supervisor.terminate_child(__MODULE__, pid_from_name(name))

  ## Callbacks

  def init(:ok), do:
    Supervisor.init([Game], strategy: :simple_one_for_one)

  ## Utility

  defp pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end
