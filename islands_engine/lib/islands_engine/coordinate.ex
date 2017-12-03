defmodule IslandsEngine.Coordinate do
  @moduledoc """
  Data structure representing game board coordinates.
  """
  alias __MODULE__

  @enforce_keys [:row, :col]
  defstruct [
    :row,
    :col
  ]

  @board_range 1..10

  @doc """
  Creates a new coordinate with the given row and column.

  Returns:
    {:ok, coordinate} if row and column values are valid;
    {:error, :invalid_coordinate} otherwise

  ## Examples

      iex> IslandsEngine.Coordinate.new(1, 10)
      {:ok, %IslandsEngine.Coordinate{col: 10, row: 1}}

      iex> IslandsEngine.Coordinate.new(-1, 1)
      {:error, :invalid_coordinate}

      iex> IslandsEngine.Coordinate.new(11, 1)
      {:error, :invalid_coordinate}

  """
  def new(row, col) when row not in(@board_range) or col not in(@board_range), do:
    {:error, :invalid_coordinate}

  def new(row, col), do: 
    {:ok, %Coordinate{row: row, col: col}}
end
