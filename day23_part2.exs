defmodule Day23 do
  def create_graph(path) do
    File.stream!(path)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.split(&1, "-"))
    |> Enum.reduce(%{}, fn [com1, com2], edges ->
      edges
      |> Map.update(com1, MapSet.new([com2]), fn s -> MapSet.put(s, com2) end)
      |> Map.update(com2, MapSet.new([com1]), fn s -> MapSet.put(s, com1) end)
    end)
  end

  def find_largest_group(edges) do
    edges
    |> Map.keys()
    |> Enum.map(fn vertex -> find_clique(vertex, edges) end)
    |> Enum.max_by(&MapSet.size/1)
    |> MapSet.to_list()
    |> Enum.sort()
  end

  def find_clique(vertex, edges) do
    edges[vertex]
    |> Enum.reduce(MapSet.new([vertex]), fn neighbour, clique_nodes ->
      contains_all_clique_nodes =
        MapSet.intersection(clique_nodes, edges[neighbour]) == clique_nodes

      case contains_all_clique_nodes do
        true -> MapSet.put(clique_nodes, neighbour)
        false -> clique_nodes
      end
    end)
  end
end

edges = Day23.create_graph("day23.data")

cycles = Day23.find_largest_group(edges)

IO.puts("")
IO.inspect(cycles |> Enum.join(","))

# 1. faster neighbour lookup => Improve performance by using maps of connections between nodes
# 2. prune unnecessary checks => agent to keep track of visited nodes, so we can skip their "web search"
