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

  def find_party(vertices, edges) do
    # TODO find all the nodes that are interconnected to each other
    # so a,b,c need connections a-b b-c a-c to be completely connected
    # do this by going over each node, checking each of its neighbours, if its connected to each already visited node, if so, add it, otherwhise dont. when we are done, we count the amount of added nodes

    split_by = floor(length(vertices) / 12)


    vertices
    |> Enum.chunk_every(split_by)
    |> Enum.map(fn chunk ->
      Task.async(fn ->
        chunk
        |> Enum.flat_map(fn vertex ->
          # finds biggest connection
          neighbours(vertex, edges)
          |> Enum.map(fn n ->
            find_party(n, edges, [vertex])
            |> Enum.sort()
          end)
          |> Enum.uniq()
        end)
        |> Enum.uniq()
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> Enum.uniq()

  end

  def find_party(vertex, edges, visited) do
    all_neighbours = neighbours(vertex, edges)
    has_required_neighbours = Enum.all?(visited, fn old -> Enum.member?(all_neighbours, old) end)
    if !has_required_neighbours do
      visited
    else

      new_neighbours =
        all_neighbours
        |> Enum.filter(fn n -> not Enum.member?(visited, n) end)
      visited = [vertex | visited]
      new_neighbours
      |> Enum.map(fn n ->
        find_party(n, edges, visited)
      end)
      |> Enum.reduce(visited, fn other_visited, max_visited ->
        if length(other_visited) > length(max_visited) do
          other_visited
        else
          max_visited
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

cycles = Day23.find_party(vertexes, edges)
 |> Enum.max_by(&length/1)

IO.puts ""
IO.inspect(cycles)

# Improve performance by using maps of connections between nodes
# also remove used nodes from further processing, because once we saw one in a web, we dont need to check for its own web anymore. probably should keep a set of seen nodes => agent?
