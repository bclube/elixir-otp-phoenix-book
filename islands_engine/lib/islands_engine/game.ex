defmodule IslandsEngine.Game do
  @moduledoc """
  Tracks the current state of a single game between two players.
  """
  alias IslandsEngine.{
    Board,
    Coordinate,
    Guesses,
    Island,
    Rules
  }
  @behaviour :gen_statem

  @timeout :timer.hours(24)
  @players [:player1, :player2]

  ## Spec

  def child_spec(_param) do
    %{
      id: __MODULE__,
      restart: :transient,
      shutdown: 5_000,
      start: {__MODULE__, :start_link, []},
      type: :worker,
    }
  end

  ## Utility

  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  ## Client methods

  @doc """
  Starts a new instance of the game server. `name` is the name of the player
  starting the game (i.e. the name of player 1).
  """
  def start_link(name) when is_binary(name), do:
    :gen_statem.start_link(via_tuple(name), __MODULE__, name, []) 

  @doc """
  Adds a second player to the `game`. `game` is the game server. `name` becomes
  the name of player 2.
  """
  def add_player(game, name) when is_binary(name), do:
    :gen_statem.call(game, {:add_player, name})

  @doc """
  Adds an island to `player`'s game board. `game` is the game server. `key` is
  the type of island to be placed. `row` and `col` designate the upper left
  coordinate at which to place the island.
  """
  def position_island(game, player, key, row, col) when player in @players, do:
    :gen_statem.call(game, {:position_island, player, key, row, col})

  @doc """
  Signals to the game server that `player` has finished placing their islands.

  Returns:
    {:ok, finished_board} when successful
    :error or {:error, message} when not successful
  """
  def set_islands(game, player) when player in @players, do:
    :gen_statem.call(game, {:set_islands, player})

  @doc """
  Adds a `player`s guess to the game board.
  """
  def guess_coordinate(game, player, row, col) when player in @players, do:
    :gen_statem.call(game, {:guess_coordinate, player, row, col})

  ## Callbacks

  def callback_mode, do: :handle_event_function

  def init(name) do
    send(self(), {:initialize, name})
    {:ok, :uninitialized, :undefined}
  end

  def handle_event(:info, {:initialize, name}, :uninitialized, _data) do
    data = case :ets.lookup(:game_state, name) do
      [] -> fresh_state(name)
      [{_key, state}] -> state
    end
    backup_data(data)
    {:next_state, :running, data, @timeout}
  end
  def handle_event(_event_type, _event_content, :uninitialized, _data), do:
    {:keep_state_and_data, :postpone}

  def handle_event({:call, from}, {:add_player, name}, _state, data) do
    with {:ok, rules} <- Rules.check(data.rules, :add_player)
    do
      data
      |> update_player2_name(name)
      |> update_rules(rules)
      |> backup_data()
      |> reply_success(from, :ok)
    else
      error -> reply_error(from, error)
    end
  end

  def handle_event({:call, from}, {:position_island, player, key, row, col}, _state, data) do
    board = player_board(data, player)
    with {:ok, rules} <- Rules.check(data.rules, {:position_islands, player}),
      {:ok, coordinate} <- Coordinate.new(row, col),
      {:ok, island} <- Island.new(key, coordinate),
      %{} = board <- Board.position_island(board, key, island)
    do
      data
      |> update_board(player, board)
      |> update_rules(rules)
      |> backup_data()
      |> reply_success(from, :ok)
    else
      error -> reply_error(from, error)
    end
  end

  def handle_event({:call, from}, {:set_islands, player}, _state, data) do
    board = player_board(data, player)
    with {:ok, rules} <- Rules.check(data.rules, {:set_islands, player}),
         true <- Board.all_islands_positioned?(board)
    do
      data
      |> update_rules(rules)
      |> backup_data()
      |> reply_success(from, {:ok, board})
    else
      :error -> reply_error(from, :error)
      false -> reply_error(from, {:error, :not_all_islands_positioned})
    end
  end

  def handle_event({:call, from}, {:guess_coordinate, player_key, row, col}, _state, data) do
    opponent_key = opponent(player_key)
    opponent_board = player_board(data, opponent_key)
    with {:ok, rules} <- Rules.check(data.rules, {:guess_coordinate, player_key}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {hit_or_miss, forested_island, win_status, opponent_board} <- Board.guess(opponent_board, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status})
    do
      data
      |> update_board(opponent_key, opponent_board)
      |> update_guesses(player_key, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> backup_data()
      |> reply_success(from, {hit_or_miss, forested_island, win_status})
    else
      error -> reply_error(from, error)
    end
  end

  def handle_event(:timeout, _event_content, _state, data), do:
    {:stop, {:shutdown, :timeout}, data}

  def terminate({:shutdown, :timeout}, _state, data) do
    :ets.delete(:game_state, data.player1.name)
    :ok
  end
  def terminate(_reason, _state, _data), do: :ok

  defp update_player2_name(data, name), do:
    put_in(data.player2.name, name)

  defp update_rules(data, rules), do: %{data | rules: rules}

  defp reply_success(data, from, reply), do:
    {:keep_state, data, [{:reply, from, reply}, @timeout]}
  defp reply_error(from, reply), do:
    {:keep_state_and_data, [{:reply, from, reply}, @timeout]}

  defp backup_data(data) do
    :ets.insert(:game_state, {data.player1.name, data})
    data
  end

  defp player_board(data, player), do: Map.get(data, player).board

  defp update_board(data, player, board), do:
    Map.update!(data, player, fn player -> %{player | board: board} end)

  defp update_guesses(data, player_key, hit_or_miss, coordinate), do:
    update_in(data[player_key].guesses, &Guesses.add(&1, hit_or_miss, coordinate))

  defp fresh_state(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    %{player1: player1, player2: player2, rules: %Rules{}}
  end

  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1
end
