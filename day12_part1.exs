defmodule Day12 do
  def solve(filepath) do
    {tile_map, max_y, max_x} = read_file_into_tile_map(filepath)
    {region_map, _, _} = create_region_map(tile_map, max_x, max_y)
    calc_cost_for_regions(region_map, tile_map)
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

  defp calc_cost_for_regions(region_map, tile_map) do
    region_keys = Map.keys(region_map)

    region_keys
    |> Enum.reduce(0, fn index, total_cost ->
      {char, coordinates} = Map.get(region_map, index, {?., []})

      fencing_cost =
        coordinates
        |> Enum.reduce(0, fn {x, y}, fencing_cost ->
          above = tile_map[{x, y - 1}]
          below = tile_map[{x, y + 1}]
          left = tile_map[{x - 1, y}]
          right = tile_map[{x + 1, y}]

          around = [above, left, right, below]

          same_chars =
            around
            |> Enum.filter(fn c -> c == char end)
            |> Enum.count()

          fencing_cost + 4 - same_chars
        end)

      region_cost = fencing_cost * length(coordinates)

      total_cost + region_cost
    end)
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
