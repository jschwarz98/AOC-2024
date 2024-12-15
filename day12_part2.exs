defmodule Day12 do
  def solve(filepath) do
    {tile_map, max_y, max_x} = read_file_into_tile_map(filepath)
    {region_map, _, _} = create_region_map(tile_map, max_x, max_y)
    calc_cost_for_regions(region_map)
  end

  defp read_file_into_tile_map(filepath) do
    File.stream!(filepath, :line)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_charlist/1)
    |> Enum.reduce({%{}, -1, -1}, fn charlist, {map, y, _} ->
      y = y + 1

      {updated_map, largest_x} =
        charlist
        |> Enum.reduce({map, -1}, fn char, {map, x} ->
          x = x + 1
          {Map.put(map, {x, y}, char), x}
        end)

      {updated_map, y, largest_x}
    end)
  end

  defp create_region_map(tile_map, max_x, max_y) do
    0..max_y
    |> Enum.reduce({%{}, 0, MapSet.new()}, fn y, acc1 ->
      0..max_x
      |> Enum.reduce(acc1, fn x, {region_map, region_count, visited_coordinates} = acc2 ->
        # todo dfs machen
        coordinate = {x, y}

        if MapSet.member?(visited_coordinates, coordinate) do
          acc2
        else
          region_coordinates = search_region(tile_map, coordinate)

          visited_coordinates = MapSet.union(visited_coordinates, region_coordinates)
          char = tile_map[coordinate]
          region_count = region_count + 1

          region_map =
            Map.put(region_map, region_count, {char, region_coordinates |> MapSet.to_list()})

          {region_map, region_count, visited_coordinates}
        end
      end)
    end)
  end

  defp calc_cost_for_regions(region_map) do
    region_keys = Map.keys(region_map)

    region_keys
    |> Enum.reduce(0, fn index, total_cost ->
      {char, coordinates} = Map.get(region_map, index, {?., []})

      # "moving along the axis" für jede koordinate, alle vier richtungen abgehen so lange wies geht, die besuchten koordinaten merken und überspringen bei weiteren checks später
      {total_sides, _visited_coordinates} =
        coordinates
        |> Enum.reduce({0, %{}}, fn coordinate, {total_sides, visited_coordinates} ->
          {found_sides, visited_coordinates} =
            [
              {:top, fn {x, y} -> {x, y - 1} end, fn {x, y} -> {x + 1, y} end},
              {:bottom, fn {x, y} -> {x, y + 1} end, fn {x, y} -> {x + 1, y} end},
              {:left, fn {x, y} -> {x - 1, y} end, fn {x, y} -> {x, y + 1} end},
              {:right, fn {x, y} -> {x + 1, y} end, fn {x, y} -> {x, y + 1} end}
            ]
            |> Enum.reduce(
              {0, visited_coordinates},
              fn {side, neighbour_check_fn, move_fn}, {count, visited_coordinates} ->
                neighbour = neighbour_check_fn.(coordinate)
                blocked_by_neighbour? = Enum.member?(coordinates, neighbour)

                already_checked_this_node? =
                  MapSet.member?(Map.get(visited_coordinates, side, MapSet.new()), coordinate)

                case blocked_by_neighbour? or already_checked_this_node? do
                  true ->
                    {count, visited_coordinates}

                  false ->
                    visited_nodes =
                      move_and_check(coordinates, coordinate, neighbour_check_fn, move_fn)

                    side_set = Map.get(visited_coordinates, side, MapSet.new())

                    visited_any_already? =
                      Enum.any?(visited_nodes, fn node -> MapSet.member?(side_set, node) end)

                    checked_coordinates_set = MapSet.union(side_set, MapSet.new(visited_nodes))

                    visited_coordinates =
                      Map.put(visited_coordinates, side, checked_coordinates_set)

                    case visited_any_already? do
                      true ->
                        {count, visited_coordinates}

                      false ->
                        {count + 1, visited_coordinates}
                    end
                end
              end
            )

          {total_sides + found_sides, visited_coordinates}
        end)

      region_cost = total_sides * length(coordinates)
      total_cost + region_cost
    end)
  end

  defp move_and_check(
         coordinates,
         coordinate,
         other_node_modifier,
         movement_modifier,
         nodes \\ []
       ) do
    in_list? = Enum.member?(coordinates, coordinate)

    other_node_coordinate = other_node_modifier.(coordinate)
    node_on_other_side? = Enum.member?(coordinates, other_node_coordinate)

    case in_list? and not node_on_other_side? do
      true ->
        new_coordinate = movement_modifier.(coordinate)

        move_and_check(coordinates, new_coordinate, other_node_modifier, movement_modifier, [
          coordinate | nodes
        ])

      false ->
        nodes
    end
  end

  defp search_region(%{} = tile_map, position) do
    dfs_region(tile_map, position, tile_map[position], MapSet.new())
  end

  defp dfs_region(%{} = tile_map, {x, y} = position, char, visited_set) do
    if MapSet.member?(visited_set, position) do
      visited_set
    else
      current = tile_map[position]

      case current do
        ^char ->
          visited_set = MapSet.put(visited_set, position)

          visited_set = dfs_region(tile_map, {x, y - 1}, char, visited_set)
          visited_set = dfs_region(tile_map, {x, y + 1}, char, visited_set)
          visited_set = dfs_region(tile_map, {x - 1, y}, char, visited_set)
          visited_set = dfs_region(tile_map, {x + 1, y}, char, visited_set)

          visited_set

        _ ->
          visited_set
      end
    end
  end
end

IO.inspect(Day12.solve("day12.data"))
