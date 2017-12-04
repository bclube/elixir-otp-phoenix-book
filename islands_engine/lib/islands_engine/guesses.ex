defmodule IslandsEngine.Guesses do
  @moduledoc """
  Data structure for keeping track of guesses made so far in the game.
  """
  alias IslandsEngine.{Coordinate, Guesses}

  @enforce_keys [:hits, :misses]
  defstruct [
    :hits,
    :misses
  ]

  @doc """
  Creates a new Guesses data structure ready to start tracking guesses.
  """
  def new, do:
    %Guesses{hits: MapSet.new(), misses: MapSet.new()}

  @doc """
  Adds coordinate as a hit in `guesses`.
  """
  def add(%Guesses{} = guesses, :hit, %Coordinate{} = coord), do:
    update_in(guesses.hits, &MapSet.put(&1, coord))

  @doc """
  Adds coordinate as a miss in `guesses`.
  """
  def add(%Guesses{} = guesses, :miss, %Coordinate{} = coord), do:
    update_in(guesses.misses, &MapSet.put(&1, coord))
end
