defmodule IslandsEngine.Rules do
  @moduledoc """
  State machine for the game engine.
  """
  alias __MODULE__

  defstruct [
    state: :initialized,
    player1: :islands_not_set,
    player2: :islands_not_set
  ]

  def new, do: %Rules{}

  @doc """
  Applies the given `action` to `state`.

  Returns:
    {:ok, new_rules} if `action` is a legal action for the current `state`. `new_state` contains the result of applying `action` to `state`.
    :error if `action` is not a legal action for the current `state`.
  """
  def check(%Rules{state: :initialized} = rules, :add_player), do:
    {:ok, %{rules | state: :players_set}}
  def check(%Rules{state: :players_set} = rules, {:position_islands, player}) do
    case Map.fetch!(rules, player) do
      :islands_set -> :error
      :islands_not_set -> {:ok, rules}
    end
  end
  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)
    case both_players_islands_set?(rules) do
      true -> {:ok, %{rules | state: :player1_turn}}
      false -> {:ok, rules}
    end
  end
  def check(%Rules{state: :player1_turn} = rules, {:guess_coordinate, :player1}), do:
    {:ok, %{rules | state: :player2_turn}}
  def check(%Rules{state: :player2_turn} = rules, {:guess_coordinate, :player2}), do:
    {:ok, %{rules | state: :player1_turn}}
  def check(%Rules{state: :player1_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %{rules | state: :game_over}}
    end
  end
  def check(%Rules{state: :player2_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %{rules | state: :game_over}}
    end
  end
  def check(_state, _action), do: :error

  defp both_players_islands_set?(%Rules{player1: :islands_set, player2: :islands_set}), do: true
  defp both_players_islands_set?(%Rules{}), do: false
end
