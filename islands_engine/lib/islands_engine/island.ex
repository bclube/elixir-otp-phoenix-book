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

  @doc """
  Creates a new Island with the given shape and upper left coordinate.

  Returns:
    {:ok, island} -> when there are no errors in the creation of the island.
    {:error, reason} -> then there is an error in the creation of an island.
  """
  def new(type, %Coordinate{}=upper_left) do
    with [_|_]=offsets <- offsets(type),
    %MapSet{}=coordinates <- add_coordinates(offsets, upper_left)
    do
      {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  @shapes  %{
    square: [{0,0}, {0,1}, {1,0}, {1,1}],
    atoll: [{0,0}, {0,1}, {1,1}, {2,0}, {2,1}],
    dot: [{0,0}],
    l_shape: [{0,0}, {1,0}, {2,0}, {2,1}],
    s_shape: [{0,1}, {0,2}, {1,0}, {1,1}]
  }

  defp offsets(key), do:
    Map.get(@shapes, key, {:error, :invalid_island_type})

  defp add_coordinates(offsets, upper_left), do:
    Enum.reduce_while(offsets, MapSet.new(), &add_coordinate(&2, upper_left, &1))

  defp add_coordinate(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coordinate} -> {:cont, MapSet.put(coordinates, coordinate)}
      {:error, _reason}=err -> {:halt, err}
    end
  end
end
