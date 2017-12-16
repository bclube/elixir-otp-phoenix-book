defmodule IslandsEngine.Game do
  @moduledoc """
  Tracks the current state of a single game between two players.
  """
  alias IslandsEngine.GameState
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
      [] -> GameState.new(name)
      [{_key, state}] -> state
    end
    backup_data!(data)
    {:next_state, :running, data, @timeout}
  end
  def handle_event(_event_type, _event_content, :uninitialized, _data), do:
    {:keep_state_and_data, :postpone}

  def handle_event({:call, from}, {:add_player, name}, _state, data) do
    case GameState.add_player(data, name) do
      {:ok, new_data} -> reply_success!(new_data, from, :ok)
      {:error, _}=err -> reply_error(from, err)
    end
  end

  def handle_event({:call, from}, {:position_island, player, key, row, col}, _state, data) do
    case GameState.position_island(data, player, key, row, col) do
      {:ok, new_data} -> reply_success!(new_data, from, :ok)
      {:error, _}=err -> reply_error(from, err)
    end
  end

  def handle_event({:call, from}, {:set_islands, player}, _state, data) do
    case GameState.set_islands(data, player) do
      {:ok, board, new_data} -> reply_success!(new_data, from, {:ok, board})
      {:error, _}=err -> reply_error(from, err)
    end
  end

  def handle_event({:call, from}, {:guess_coordinate, player_key, row, col}, _state, data) do
    case GameState.guess_coordinate(data, player_key, row, col) do
      {:ok, result, new_data} -> reply_success!(new_data, from, result)
      {:error, _}=err -> reply_error(from, err)
    end
  end

  def handle_event(:timeout, _event_content, _state, data), do:
    {:stop, {:shutdown, :timeout}, data}

  def terminate({:shutdown, :timeout}, _state, data) do
    :ets.delete(:game_state, data.player1.name)
    :ok
  end
  def terminate(_reason, _state, _data), do: :ok

  defp reply_success!(data, from, reply) do
    backup_data!(data)
    {:keep_state, data, [{:reply, from, reply}, @timeout]}
  end
  defp reply_error(from, reply), do:
    {:keep_state_and_data, [{:reply, from, reply}, @timeout]}

  defp backup_data!(data), do:
    :ets.insert(:game_state, {data.player1.name, data})
end
