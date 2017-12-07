defmodule IslandsEngine.Game do
  @moduledoc """
  GenServer encapsulating the current state of a single game between two players.
  """
  alias IslandsEngine.{
    Board,
    Coordinate,
    Guesses,
    Island,
    Rules
  }
  use GenServer

  @players [:player1, :player2]

  ## Client methods

  @doc """
  Starts a new instance of the game server. `name` is the name of the player
  starting the game (i.e. the name of player 1).
  """
  def start_link(name) when is_binary(name), do:
    GenServer.start_link(__MODULE__, name, [])

  @doc """
  Adds a second player to the `game`. `game` is the game server. `name` becomes
  the name of player 2.
  """
  def add_player(game, name) when is_binary(name), do:
    GenServer.call(game, {:add_player, name})

  @doc """
  Adds an island to `player`'s game board. `game` is the game server. `key` is
  the type of island to be placed. `row` and `col` designate the upper left
  coordinate to use at which to place the island.
  """
  def position_island(game, player, key, row, col) when player in @players, do:
    GenServer.call(game, {:position_island, player, key, row, col})

  ## Callbacks

  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: %Rules{}}}
  end

  def handle_call({:add_player, name}, _from, state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :add_player)
    do
      state_data
      |> update_player2_name(name)
      |> update_rules(rules)
      |> reply(:ok)
    else
      error -> {:reply, error, state_data}
    end
  end

  def handle_call({:position_island, player, key, row, col}, _from, state_data) do
    board = player_board(state_data, player)
    with {:ok, rules} <- Rules.check(state_data.rules, {:position_islands, player}),
      {:ok, coordinate} <- Coordinate.new(row, col),
      {:ok, island} <- Island.new(key, coordinate),
      %{} = board <- Board.position_island(board, key, island)
    do
      state_data
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply(:ok)
    else
      error -> {:reply, error, state_data}
    end
  end

  defp update_player2_name(state_data, name), do:
    put_in(state_data.player2.name, name)

  defp update_rules(state_data, rules), do: %{state_data | rules: rules}

  defp reply(state_data, reply), do: {:reply, reply, state_data}

  defp player_board(state_data, player), do: Map.get(state_data, player).board

  defp update_board(state_data, player, board), do:
    Map.update!(state_data, player, fn player -> %{player | board: board} end)
end
