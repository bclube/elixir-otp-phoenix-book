defmodule IslandsEngine.GameState do
  @behaviour Access

  alias IslandsEngine.{
    Board,
    Coordinate,
    GameState,
    Guesses,
    Island,
    Rules,
  }

  @enforce_keys [
    :player1,
    :player2,
    :rules,
  ]
  defstruct [
    :player1,
    :player2,
    :rules,
  ]

  ## Access behaviour

  def fetch(%__MODULE__{}=gs, key), do:
    Map.fetch(gs, key)

  def get(%__MODULE__{}=gs, key, default), do:
    Map.get(gs, key, default)

  def get_and_update(%__MODULE__{}=gs, key, function), do:
    Map.get_and_update(gs, key, function)

  def pop(%__MODULE__{}, _key), do:
    raise "#{__MODULE__}.pop() not implemented" # Don't pop from struct where keys are required

  def new(name) when is_binary(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    %__MODULE__{player1: player1, player2: player2, rules: %Rules{}}
  end

  def add_player(%__MODULE__{}=game, name) when is_binary(name) do
    with {:ok, rules} <- Rules.check(game.rules, :add_player)
    do
      game
      |> update_player2_name(name)
      |> update_rules(rules)
      |> success_response()
    else
      error -> error_response(error)
    end
  end

  def position_island(%__MODULE__{}=game, player, key, row, col) do
    board = player_board(game, player)
    with {:ok, rules} <- Rules.check(game.rules, {:position_islands, player}),
      {:ok, island} <- Island.new(key, row, col),
      %{} = board <- Board.position_island(board, island)
    do
      game
      |> update_board(player, board)
      |> update_rules(rules)
      |> success_response()
    else
      error -> error_response(error)
    end
  end

  def set_islands(%__MODULE__{}=game, player) do
    board = player_board(game, player)
    with {:ok, rules} <- Rules.check(game.rules, {:set_islands, player})
    do
      if Board.all_islands_positioned?(board) do
        game
        |> update_rules(rules)
        |> success_response(board)
      else
        error_response(:not_all_islands_positioned)
      end
    else
      error -> error_response(error)
    end
  end

  def guess_coordinate(%__MODULE__{}=game, player_key, row, col) do
    opponent_key = opponent(player_key)
    opponent_board = player_board(game, opponent_key)
    with {:ok, rules} <- Rules.check(game.rules, {:guess_coordinate, player_key}),
         {hit_or_miss, forested_island, win_status, opponent_board} <- Board.guess(opponent_board, row, col),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status})
    do
      game
      |> update_board(opponent_key, opponent_board)
      |> update_guesses(player_key, hit_or_miss, row, col)
      |> update_rules(rules)
      |> success_response({hit_or_miss, forested_island, win_status})
    else
      error -> error_response(error)
    end
  end

  defp success_response(game), do: {:ok, game}
  defp success_response(game, response), do: {:ok, response, game}

  defp error_response({:error, _reason}=err), do: err
  defp error_response(error), do: {:error, error}

  defp update_player2_name(game, name), do:
    put_in(game.player2.name, name)

  defp update_rules(game, rules), do:
    %{game | rules: rules}

  defp player_board(game, player), do: Map.get(game, player).board

  defp update_board(game, player, board), do:
    Map.update!(game, player, fn player -> %{player | board: board} end)

  defp update_guesses(game, player_key, hit_or_miss, row, col) do
    coordinate = Coordinate.new(row, col)
    update_in(game[player_key].guesses, &Guesses.add(&1, hit_or_miss, coordinate))
  end

  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1
end
