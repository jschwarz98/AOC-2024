defmodule Day23 do
  def create_graph(path) do
    {edges, vertices} =
      File.stream!(path)
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.split(&1, "-"))
      |> Enum.reduce({%{}, MapSet.new()}, fn [com1, com2], {edges, vertices} ->
        vertices =
          vertices
          |> MapSet.put(com1)
          |> MapSet.put(com2)

        edges =
          edges
          |> Map.update(com1, [com2], fn l -> [com2 | l] end)
          |> Map.update(com2, [com1], fn l -> [com1 | l] end)

        {edges, vertices}
      end)

    {edges, vertices |> MapSet.to_list()}
  end

  def find_party(vertices, edges) do
    {:ok, agent} = Agent.start(fn -> MapSet.new() end)
    split_by = floor(length(vertices) / 12)

    vertices
    |> Enum.chunk_every(split_by)
    |> Enum.map(fn chunk ->
      Task.async(fn ->
        chunk
        |> Enum.flat_map(fn vertex ->
          case Agent.get(agent, fn state -> MapSet.member?(state, vertex) end) do
            true ->
              []

            false ->
              party_for_vertex =
                edges[vertex]
                |> Enum.map(fn n -> find_party(n, edges, [vertex]) end)
                |> Enum.map(&Enum.sort/1)
                |> Enum.uniq()
                |> Enum.max_by(&length/1)

              Agent.update(agent, fn state ->
                party_for_vertex
                |> Enum.reduce(state, fn node, state -> MapSet.put(state, node) end)
                |> MapSet.put(vertex)
              end)

              party_for_vertex
          end
        end)
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> Enum.uniq()
  end

  def find_party(vertex, edges, visited) do
    all_neighbours = edges[vertex]
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
end

{edges, vertexes} = Day23.create_graph("day23.data")

cycles =
  Day23.find_party(vertexes, edges)
  |> Enum.max_by(&length/1)

IO.puts("")
IO.inspect(cycles)

# 1. faster neighbour lookup => Improve performance by using maps of connections between nodes
# 2. prune unnecessary checks => agent to keep track of visited nodes, so we can skip their "web search"
