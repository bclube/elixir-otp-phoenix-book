defmodule IslandsEngine.Island do
  @moduledoc """
  Data structure for island location coordinates; hit and unhit.
  """
  alias IslandsEngine.{Coordinate, Island}

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [
    :coordinates,
    :hit_coordinates
  ]

  @shapes  %{
    square: [{0,0}, {0,1}, {1,0}, {1,1}],
    atoll: [{0,0}, {0,1}, {1,1}, {2,0}, {2,1}],
    dot: [{0,0}],
    l_shape: [{0,0}, {1,0}, {2,0}, {2,1}],
    s_shape: [{0,1}, {0,2}, {1,0}, {1,1}]
  }

  @doc """
  Creates a new Island with the given shape and upper left coordinate.

  Returns:
    {:ok, island} -> when there are no errors in the creation of the island.
    {:error, reason} -> then there is an error in the creation of an island.
  """
  def new(type, row, col) do
    with [_|_]=offsets <- Map.get(@shapes, type, {:error, :invalid_island_type})
    do
      coordinates = Enum.into(offsets, MapSet.new(), fn {r, c} -> Coordinate.new(r + row, c + col) end)
      {:ok, %Island{type: type, coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  @doc """
  Returns true if any of the `new_island`'s coordinates match any of `existing_island`'s
  coordinates.

  ## Examples

      iex> with {:ok, i1} = IslandsEngine.Island.new(:dot, 1, 1),
      ...>    {:ok, i2} = IslandsEngine.Island.new(:dot, 1, 2),
      ...>    do: IslandsEngine.Island.overlaps?(i1, i2)
      false

      iex> with {:ok, i1} = IslandsEngine.Island.new(:square, 2, 2),
      ...>    {:ok, i2} = IslandsEngine.Island.new(:square, 1, 1),
      ...>    do: IslandsEngine.Island.overlaps?(i1, i2)
      true

  """
  def overlaps?(%Island{} = existing_island, %Island{} = new_island), do:
    not MapSet.disjoint?(existing_island.coordinates, new_island.coordinates)

  @doc """
  Adds `coordinate` to `island`'s guesses.

  Returns:
    {:hit, new_island} when the guess hits the island. `new_island` is the updated island record.
    :miss when the guess does not hit the island.
  """
  def guess(%Island{} = island, row, col) do
    coordinate = Coordinate.new(row, col)
    if MapSet.member?(island.coordinates, coordinate) do
      {:hit, update_in(island.hit_coordinates, &MapSet.put(&1, coordinate))}
    else
      :miss
    end
  end

  @doc """
  Returns a list of valid island types.
  """
  def types, do:
    Map.keys(@shapes) |> Enum.sort()

  @doc """
  Returns true when `island` is completely forested; false otherwise.
  """
  def forested?(%Island{} = island), do:
    MapSet.equal?(island.coordinates, island.hit_coordinates)
end
