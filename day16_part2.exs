defmodule Day16 do
  def solve(filepath) do
    {map, _y_index} =
      File.stream!(filepath)
      |> Enum.reduce({%{}, 0}, fn line, {map, y} ->
        {map, _} =
          line
          |> String.to_charlist()
          |> Enum.reduce({map, 0}, fn char, {map, x} ->
            {Map.put(map, {x, y}, char), x + 1}
          end)

        {map, y + 1}
      end)

    {nodes, _y_index} =
      File.stream!(filepath)
      |> Enum.chunk_every(3, 1, :discard)
      |> Enum.reduce({%{}, 1}, fn [l1, l2, l3], {nodes, y} ->
        l1_chars = l1 |> String.trim() |> String.to_charlist()
        l2_chars = l2 |> String.trim() |> String.to_charlist()
        l3_chars = l3 |> String.trim() |> String.to_charlist()

        {nodes, _x_index} =
          l1_chars
          |> Enum.zip(l2_chars)
          |> Enum.zip(l3_chars)
          # {{l1,l2}, l3}
          |> Enum.chunk_every(3, 1, :discard)
          |> Enum.reduce({nodes, 1}, fn [
                                          {{_, above}, _},
                                          {{left, center}, right},
                                          {{_, below}, _}
                                        ] = chunk,
                                        {nodes, x} ->
            nodes =
              case center do
                ?# ->
                  nodes

                ?S ->
                  Map.put(nodes, :start, {x, y})

                ?E ->
                  Map.put(nodes, :end, {x, y})

                ?.
                when (above == ?. and (left == ?. or right == ?.)) or
                       (below == ?. and (left == ?. or right == ?.)) ->
                  count =
                    nodes
                    |> Map.keys()
                    |> Enum.filter(fn key -> key != :start and key != :end end)
                    |> Enum.count()

                  Map.put(nodes, count, {x, y})

                _ ->
                  nodes
              end

            {nodes, x + 1}
          end)

        {nodes, y + 1}
      end)

    edges =
      nodes
      |> Map.keys()
      |> Enum.reduce(%{}, fn key, edges ->
        {x, y} = nodes[key]

        nodes
        |> Map.keys()
        |> Enum.filter(fn other_key -> other_key != key end)
        |> Enum.filter(fn other_key ->
          case nodes[other_key] do
            {^x, other_y} ->
              # walk through y axis and check for walls
              range =
                case other_y > y do
                  true -> y..other_y
                  false -> other_y..y
                end

              range
              |> Enum.reduce(true, fn ty, no_walls? ->
                case no_walls? do
                  false ->
                    false

                  true ->
                    case map[{x, ty}] do
                      ?# -> false
                      _ -> true
                    end
                end
              end)

            {other_x, ^y} ->
              # walk through x axis and check for walls
              range =
                case other_x > x do
                  true -> x..other_x
                  false -> other_x..x
                end

              range
              |> Enum.reduce(true, fn tx, no_walls? ->
                case no_walls? do
                  false ->
                    false

                  true ->
                    case map[{tx, y}] do
                      ?# -> false
                      _ -> true
                    end
                end
              end)

            _ ->
              false
          end
        end)
        |> Enum.filter(fn other_key ->
          not Map.has_key?(edges, {key, other_key}) and not Map.has_key?(edges, {other_key, key})
        end)
        |> Enum.reduce(edges, fn other_key, edges ->
          {other_x, other_y} = nodes[other_key]

          cost = abs(other_x - x) + abs(other_y - y)

          Map.put(edges, {key, other_key}, cost)
        end)
      end)

    distance_from_start =
      nodes
      |> Map.keys()
      |> Enum.reduce(%{}, fn node, distances ->
        case node do
          :start -> Map.put(distances, node, 0)
          _ -> Map.put(distances, node, 2_000_000_000)
        end
      end)

    previous_nodes = %{}

    {distances, previous} = dijkstra(nodes, nodes, edges, distance_from_start, previous_nodes)

    visited_nodes = backtrace(previous)

    target = distances[:end]

    all_edges = edges |> Map.keys()

    used_edges =
      visited_nodes
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.reduce([], fn [node1, node2], used ->
        used_edge =
          all_edges
          |> Enum.filter(fn {e1, e2} ->
            (e1 == node1 and e2 == node2) or (e1 == node2 and e2 == node1)
          end)
          |> List.first()

        [used_edge | used]
      end)

    other_possible_solutions =
      used_edges
      |> Enum.reduce([], fn used_edge, other_solutions ->
        new_edges = Map.drop(edges, [used_edge])

        distance_from_start =
          nodes
          |> Map.keys()
          |> Enum.reduce(%{}, fn node, distances ->
            case node do
              :start -> Map.put(distances, node, 0)
              _ -> Map.put(distances, node, 2_000_000_000)
            end
          end)

        {distance, previous} = dijkstra(nodes, nodes, new_edges, distance_from_start, %{})
        IO.puts("back out here")
        result = distance[:end]
          IO.inspect(result)
        visited = backtrace(previous)
        IO.inspect({"without", used_edge, "=", result, " <= ", visited})

        case result do
          ^target -> [visited | other_solutions]
          _ -> other_solutions
        end
      end)
      |> Enum.reduce(MapSet.new(used_edges), fn solution, edges_set ->
        solution
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.reduce(edges_set, fn [node1, node2], set ->
          case MapSet.member?(set, {node1, node2}) or MapSet.member?(set, {node2, node1}) do
            true -> set
            false -> MapSet.put(set, {node1, node2})
          end
        end)
      end)
      |> MapSet.to_list()
      |> Enum.reduce(MapSet.new(), fn {node1, node2}, visited_coordinates ->
        {x, y} = nodes[node1]

        coordinates =
          case nodes[node2] do
            {^x, y2} ->
              range =
                case y2 > y do
                  true -> y..y2
                  false -> y2..y
                end

              range
              |> Enum.map(fn yy -> {x, yy} end)

            {x2, ^y} ->
              range =
                case x2 > x do
                  true -> x..x2
                  false -> x2..x
                end

              range
              |> Enum.map(fn xx -> {xx, y} end)
          end

        MapSet.union(MapSet.new(coordinates), visited_coordinates)
      end)
      |> MapSet.to_list()
      |> Enum.count()
  end

  defp backtrace(previous, acc \\ [], current \\ :end) do
    IO.inspect({"backtracing", current, acc})
    case current do
      :start ->
        [current | acc]
      nil -> acc

      _ ->
        prev = previous[current]
        backtrace(previous, [current | acc], prev)
    end
  end

  defp dijkstra(all_nodes, nodes, edges, distance_from_start, previous_nodes) do
    remaining_nodes = Map.keys(nodes)

    case remaining_nodes do
      [] ->
        IO.puts("done :)")
        {distance_from_start, previous_nodes}

      remaining_nodes ->
        IO.inspect({"remaining nodes...", remaining_nodes})
        min_distance_node =
          remaining_nodes
          |> Enum.map(fn node -> {node, distance_from_start[node]} end)
          |> Enum.min_by(fn {node, distance} -> distance end)
          |> elem(0)

        IO.inspect({"min distance node", min_distance_node})

        updated_nodes = Map.drop(nodes, [min_distance_node])
        IO.inspect({"updated_nodes", updated_nodes})

        {updated_distances, updated_previous} =
          edges
          |> Map.keys()
          |> Enum.filter(fn {k1, k2} -> k1 == min_distance_node or k2 == min_distance_node end)
          |> Enum.reduce({distance_from_start, previous_nodes}, fn neighbouring_node_info,
                                                                   {distances, previous} ->
            {min_distance_node, neighbouring_node} =
              case neighbouring_node_info do
                {^min_distance_node, n} -> {min_distance_node, n}
                {n, ^min_distance_node} -> {min_distance_node, n}
              end

            distance_to_neighbour =
              case edges[{neighbouring_node, min_distance_node}] do
                d when is_number(d) ->
                  d

                d when is_nil(d) ->
                  edges[{min_distance_node, neighbouring_node}]
              end

            previous_node =
              case previous[min_distance_node] do
                nil -> :start
                n -> n
              end

            coordinates = all_nodes[min_distance_node]

            current_direction =
              case min_distance_node do
                :start ->
                  :right

                _ ->
                  prev_coordinates = all_nodes[previous_node]

                  direction =
                    case {prev_coordinates, coordinates} do
                      {{px, py}, {x, y}} when px < x -> :right
                      {{px, py}, {x, y}} when px > x -> :left
                      {{px, py}, {x, y}} when py < y -> :down
                      {{px, py}, {x, y}} when py > y -> :up
                    end
              end

            neighbour_coordinates = all_nodes[neighbouring_node]

            going_direction =
              case {coordinates, neighbour_coordinates} do
                {{px, py}, {x, y}} when px < x -> :right
                {{px, py}, {x, y}} when px > x -> :left
                {{px, py}, {x, y}} when py < y -> :down
                {{px, py}, {x, y}} when py > y -> :up
              end

            degree_change =
              case {current_direction, going_direction} do
                {:left, :right} -> 180
                {:right, :left} -> 180
                {:up, :down} -> 180
                {:down, :up} -> 180
                {d, d} -> 0
                _ -> 90
              end

            alternative_distance =
              distances[min_distance_node] + distance_to_neighbour +
                floor(degree_change / 90) * 1000

            {updated_distances, updated_previous} =
              case alternative_distance < distances[neighbouring_node] do
                true ->
                  {Map.put(distances, neighbouring_node, alternative_distance),
                   Map.put(previous, neighbouring_node, min_distance_node)}

                false ->
                  {distances, previous}
              end
          end)

        IO.inspect({"updated distances and previous", updated_distances, updated_previous})

        dijkstra(all_nodes, updated_nodes, edges, updated_distances, updated_previous)
    end
  end
end

[filepath | _] = System.argv()
IO.inspect(Day16.solve(filepath))
