defmodule IslandsEngine.Rules do
  @moduledoc """
  State machine for the game engine.
  """

  @player_names [:player1, :player2]

  def new, do: :initialized

  defp turn(player), do: {:turn, player}
  defp other_player(:player1), do: :player2
  defp other_player(:player2), do: :player1
  defp next_turn(player), do: player |> other_player() |> turn()
  defp islands_placed(player), do: {:placing_islands, other_player(player)}

  @doc """
  Applies the given `action` to `state`.

  Returns:
    {:ok, new_state} if `action` is a legal action for the current `state`. `new_state` contains the result of applying `action` to `state`.
    {:error, reason} if `action` is not a legal action for the current `state`. `reason` is the reason for the failure.

  ## Examples

      iex> IslandsEngine.Rules.check(:initialized, :add_player)
      {:ok, :placing_islands}

      iex> IslandsEngine.Rules.check(:placing_islands, {:position_island, :not_a_player})
      {:error, :invalid_player_name}

      iex> IslandsEngine.Rules.check(:placing_islands, {:position_island, :player1})
      {:ok, :placing_islands}

      iex> IslandsEngine.Rules.check(:placing_islands, {:set_islands, :player1})
      {:ok, {:placing_islands, :player2}}

      iex> IslandsEngine.Rules.check({:placing_islands, :player2}, {:position_island, :player2})
      {:ok, {:placing_islands, :player2}}

      iex> IslandsEngine.Rules.check({:placing_islands, :player2}, {:position_island, :player1})
      {:error, :islands_already_set}

      iex> IslandsEngine.Rules.check({:placing_islands, :player2}, {:set_islands, :player1})
      {:ok, {:placing_islands, :player2}}

      iex> IslandsEngine.Rules.check({:placing_islands, :player2}, {:set_islands, :not_a_player})
      {:error, :invalid_player_name}

      iex> IslandsEngine.Rules.check({:placing_islands, :player2}, {:set_islands, :player2})
      {:ok, {:turn, :player1}}

      iex> IslandsEngine.Rules.check({:turn, :player1}, {:guess_coordinate, :not_a_player})
      {:error, :invalid_player_name}

      iex> IslandsEngine.Rules.check({:turn, :player1}, {:guess_coordinate, :player1})
      {:ok, {:turn, :player2}}

      iex> IslandsEngine.Rules.check({:turn, :player2}, {:guess_coordinate, :player1})
      {:error, :not_your_turn}

      iex> IslandsEngine.Rules.check({:turn, :player2}, {:win_check, :no_win})
      {:ok, {:turn, :player2}}

      iex> IslandsEngine.Rules.check({:turn, :player2}, {:win_check, :win})
      {:ok, :game_over}

  """
  def check(:initialized, :add_player), do: {:ok, :placing_islands}

  def check(_state, {:position_island, p}) when p not in @player_names, do: {:error, :invalid_player_name}
  def check(:placing_islands=state, {:position_island, _p}), do: {:ok, state}
  def check({:placing_islands, p}=state, {:position_island, p}), do: {:ok, state}
  def check({:placing_islands, _p1}, {:position_island, _p2}), do: {:error, :islands_already_set}

  def check(_state, {:set_islands, p}) when p not in @player_names, do: {:error, :invalid_player_name}
  def check(:placing_islands, {:set_islands, p}), do: {:ok, islands_placed(p)}
  def check({:placing_islands, p}, {:set_islands, p}), do: {:ok, turn(:player1)}
  def check({:placing_islands, _p1}=state, {:set_islands, _p2}), do: {:ok, state}

  def check(_state, {:guess_coordinate, p}) when p not in @player_names, do: {:error, :invalid_player_name}
  def check({:turn, player}, {:guess_coordinate, player}), do: {:ok, next_turn(player)}
  def check({:turn, _p1}, {:guess_coordinate, _p2}), do: {:error, :not_your_turn}

  def check({:turn, _player}, {:win_check, :win}), do: {:ok, :game_over}
  def check({:turn, _player}=state, {:win_check, :no_win}), do: {:ok, state}

  def check(_state, _action), do: {:error, :invalid_action_for_state}
end
