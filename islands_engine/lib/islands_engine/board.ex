defmodule IslandsEngine.Board do
  @moduledoc """
  Data structure representing state of game board.
  """
  alias IslandsEngine.{Coordinate, Island}

  @valid_rows 1..10
  @valid_columns 1..10

  @doc """
  Create a new board.
  """
  def new, do: %{}

  @doc """
  Position an island on the board.

  Returns:
    new_board with island placed accordingly if island could legally be placed on the board
    {:error, reason} if island could not legally be placed on the board
  """
  def position_island(board, %Island{} = island) do
    cond do
      island_out_of_bounds?(island) -> {:error, :island_out_of_bounds}
      overlaps_existing_island?(board, island) -> {:error, :overlapping_island}
      :default -> Map.put(board, island.type, island)
    end
  end

  @doc """
  Returns true if all island types have been placed on the board.
  """
  def all_islands_positioned?(board), do:
    Enum.all?(Island.types, &Map.has_key?(board, &1))

  @doc """

  """
  def guess(board, row, col) do
    board
    |> check_all_islands(row, col)
    |> guess_response(board)
  end

  defp coordinate_out_of_bounds?(%Coordinate{row: row, col: col}), do:
    row not in @valid_rows or col not in @valid_columns

  defp island_out_of_bounds?(island), do:
    Enum.any?(island.coordinates, &coordinate_out_of_bounds?/1)

  defp overlaps_existing_island?(board, %Island{type: type} = new_island) do
    board
    |> Map.delete(type)
    |> Map.values()
    |> Enum.any?(&Island.overlaps?(&1, new_island))
  end

  defp check_all_islands(board, row, col) do
    board
    |> Map.values()
    |> Enum.find_value(:miss, &check_island(&1, row, col))
  end

  defp check_island(island, row, col) do
    case Island.guess(island, row, col) do
      {:hit, island} -> island
      :miss -> false
    end
  end

  defp guess_response(:miss, board), do: {:miss, :none, :no_win, board}
  defp guess_response(island, board) do
    board = %{board| island.type => island}
    {:hit, forest_check(island), win_check(board), board}
  end

  defp forest_check(island), do:
    if Island.forested?(island), do: island.type, else: :none

  defp win_check(board), do:
    if all_forested?(board), do: :win, else: :no_win

  defp all_forested?(board), do:
    board |> Map.values() |> Enum.all?(&Island.forested?/1)
end
