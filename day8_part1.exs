defmodule Day8 do
  def unique_antinodes(map) do
    max_y = length(map) - 1
    max_x = String.length(hd(map)) - 1

    # step 1
    ## create map of all the letters / numbers in the map and their coordinates
    {_, map_tracker} =
      Enum.reduce(map, {0, %{}}, fn line, {y_index, map_tracker} ->
        {_, map_tracker} =
          Enum.reduce(String.to_charlist(line), {0, map_tracker}, fn char, acc ->
            {x_index, map_tracker} = acc

            case char do
              ?. ->
                {x_index + 1, map_tracker}

              _ ->
                coords = Map.get(map_tracker, char, [])
                map_tracker = Map.put(map_tracker, char, [{x_index, y_index} | coords])
                {x_index + 1, map_tracker}
            end
          end)

        {y_index + 1, map_tracker}
      end)

    # step 2
    ## for each letter / number calculate the unique resonant frequencies.  set to prevent douplicate entries
    antinodes =
      Map.keys(map_tracker)
      |> Enum.flat_map(fn key ->
        indexes = map_tracker[key]
        calculate_resonances(indexes)
      end)
      |> Enum.reduce(MapSet.new(), &MapSet.put(&2, &1))

    MapSet.to_list(antinodes)
    |> Enum.filter(fn {x, y} -> x >= 0 and x <= max_x and y >= 0 and y <= max_y end)
    |> Enum.count()
  end

  defp calculate_resonances(indexes) do
    # zip each coordinate with the other coordinates
    Enum.zip(indexes, other_values(indexes))
    |> Enum.flat_map(fn {index, other_indexes} ->
      {my_x, my_y} = index

      other_indexes
      |> Enum.map(fn {other_x, other_y} ->
        x_dif = other_x - my_x
        y_dif = other_y - my_y

        new_x = my_x + 2 * x_dif
        new_y = my_y + 2 * y_dif

        {new_x, new_y}
      end)
    end)
  end

  def other_values(numbers) do
    # turn this list into a list of lists, each with one number missing
    total_amount = Enum.count(numbers)

    0..(total_amount - 1)
    |> Enum.map(fn exclude_index ->
      Enum.slice(numbers, 0, exclude_index) ++
        Enum.slice(numbers, exclude_index + 1, total_amount - exclude_index)
    end)
  end
end

map =
  File.stream!("day8.data", :line)
  |> Enum.map(&String.trim/1)

count = Day8.unique_antinodes(map)
IO.inspect(count)
