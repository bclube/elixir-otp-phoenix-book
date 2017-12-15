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

  @doc """
  Creates a new coordinate with the given row and column.

  ## Examples

      iex> IslandsEngine.Coordinate.new(1, 10)
      %IslandsEngine.Coordinate{col: 10, row: 1}

      iex> IslandsEngine.Coordinate.new(15, 20)
      %IslandsEngine.Coordinate{col: 20, row: 15}

  """
  def new(row, col), do: %Coordinate{row: row, col: col}
end
