defmodule IslandsEngine.Guesses do
  @moduledoc """
  Data structure for keeping track of guesses made so far in the game.
  """
  alias __MODULE__
  alias IslandsEngine.Coordinate

  @enforce_keys [:hits, :misses]
  defstruct [
    :hits,
    :misses
  ]

  def new, do:
    %Guesses{hits: MapSet.new(), misses: MapSet.new()}

  @doc """
  Adds coordinate as a hit in `guesses`.
  """
  def add_hit(%__MODULE__{}=guesses, %Coordinate{}=coord), do:
    update_in(guesses.hits, &MapSet.put(&1, coord))

  @doc """
  Adds coordinate as a miss in `guesses`.
  """
  def add_miss(%__MODULE__{}=guesses, %Coordinate{}=coord), do:
    update_in(guesses.misses, &MapSet.put(&1, coord))
end
