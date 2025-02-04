defmodule Day23 do
  def create_graph(path) do
    {edges, vertices} =
      File.stream!(path)
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.split(&1, "-"))
      |> Enum.reduce({MapSet.new(), MapSet.new()}, fn [com1, com2], {edges, vertices} ->
        vertices =
          vertices
          |> MapSet.put(com1)
          |> MapSet.put(com2)

        edges =
          case com1 < com2 do
            true -> edges |> MapSet.put({com1, com2})
            false -> edges |> MapSet.put({com2, com1})
          end

        {edges, vertices}
      end)

    {edges |> MapSet.to_list(), vertices |> MapSet.to_list()}
  end

  def find_cycle(vertices, edges, depth \\ 3) do
    vertices
    |> Enum.flat_map(fn vertex ->
      cycles(vertex, vertex, [vertex], edges, depth)
    end)
    |> Enum.map(&Enum.sort/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp cycles(start, current, path, edges, max_depth, cycles \\ []) do
    neighbours = neighbours(current, edges)

    found_start? = neighbours |> Enum.member?(start)

    case found_start? and length(path) > 2 do
      true ->
        [path | cycles]

      false ->
        remaining_neighbours =
          neighbours
          |> Enum.filter(fn n -> !Enum.member?(path, n) end)

        remaining_neighbours
        |> Enum.reduce(cycles, fn n, found_cycles ->
          case length(path) do
            ^max_depth ->
              found_cycles

            _ ->
              cycles(start, n, [n | path], edges, max_depth, found_cycles)
          end
        end)
    end
  end

  defp neighbours(vertex, edges) do
    edges
    |> Enum.filter(fn {com1, com2} -> com1 == vertex or com2 == vertex end)
    |> Enum.map(fn {com1, com2} ->
      case vertex do
        ^com1 -> com2
        ^com2 -> com1
      end
    end)
  end

  def contains_letter_t(connections) do
    connections
    |> Enum.filter(fn cons -> Enum.any?(cons, &String.starts_with?(&1, "t")) end)
    |> Enum.count()
  end
end

{edges, vertexes} = Day23.create_graph("day23.data")

cycles = Day23.find_cycle(vertexes, edges)
c = Day23.contains_letter_t(cycles)

IO.inspect(c)
