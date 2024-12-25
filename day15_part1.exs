defmodule Day15 do
  def solve(filepath) do
    {map, robot_position, commands} =
      File.stream!(filepath, :line)
      |> parse_map()

    {updated_map, _} = move_robot(map, robot_position, commands)

    IO.puts("=====")
    draw_map(updated_map)

    calculate_gps_cost(updated_map)
  end

  defp calculate_gps_cost(map) do
    Map.keys(map)
    |> Enum.reduce(0, fn {x, y} = key, sum ->
      char = map[key]

      case char do
        ?O ->
          sum + x + 100 * y

        _ ->
          sum
      end
    end)
  end

  defp draw_map(map) do
    keys = Map.keys(map)

    max_x = keys |> Enum.map(fn {x, y} -> x end) |> Enum.max()
    max_y = keys |> Enum.map(fn {x, y} -> y end) |> Enum.max()

    lines =
      0..max_y
      |> Enum.map(fn y ->
        line =
          0..max_x
          |> Enum.map(fn x -> List.to_string([map[{x, y}]]) end)
          |> Enum.join()
      end)
      |> Enum.join("\n")

    IO.puts(lines)
  end

  defp move_robot(map, _, []), do: {map, 0}

  defp move_robot(%{} = map, robot_position, [command | commands])
       when is_list(commands) do
    direction =
      case command do
        ?< -> :left
        ?^ -> :up
        ?> -> :right
        ?v -> :down
      end

    {map, robot_position} = move_direction(map, robot_position, direction)

    move_robot(map, robot_position, commands)
  end

  defp move_direction(map, {x, y} = tile, direction) do
    next_char_position =
      case direction do
        :up -> {x, y - 1}
        :down -> {x, y + 1}
        :left -> {x - 1, y}
        :right -> {x + 1, y}
      end

    # try to make space for the robot
    next_char = map[next_char_position]
    char = Map.get(map, tile)

    case next_char do
      nil ->
        # out of bounds
        {map, tile}

      ?# ->
        # wall
        {map, tile}

      ?. ->
        # empty space
        # so move into empty tile
        {map |> Map.put(tile, ?.) |> Map.put(next_char_position, char), next_char_position}

      _ ->
        # robot or crate

        # so try to make space
        {updated_map, _} = move_direction(map, next_char_position, direction)

        # check if after updating the map its now empty
        next_char = updated_map[next_char_position]

        # if there is space, we move into the empty tile
        case next_char do
          ?. ->
            {updated_map |> Map.put(next_char_position, char) |> Map.put(tile, ?.),
             next_char_position}

          _ ->
            {updated_map, tile}
        end
    end
  end

  defp parse_map(lines) do
    {_, map, robot_position, commands, _} =
      lines
      |> Enum.map(&String.trim/1)
      |> Enum.reduce({:reading_map, %{}, {-1, -1}, [], 0}, fn line,
                                                              {mode, map, robot_position,
                                                               commands, y} ->
        case mode do
          :reading_map ->
            case line do
              "" ->
                {:reading_commands, map, robot_position, commands, y}

              l ->
                {map, robot_position, _} =
                  l
                  |> String.to_charlist()
                  |> Enum.reduce({map, robot_position, 0}, fn char, {m, r, x} ->
                    r =
                      case char do
                        ?@ -> {x, y}
                        _ -> r
                      end

                    {Map.put(m, {x, y}, char), r, x + 1}
                  end)

                {mode, map, robot_position, commands, y + 1}
            end

          :reading_commands ->
            commands =
              line
              |> String.to_charlist()
              |> Enum.reduce(commands, fn char, cmds ->
                [char | cmds]
              end)

            {mode, map, robot_position, commands, y}
        end
      end)

    {map, robot_position, Enum.reverse(commands)}
  end
end

[filepath | _] = System.argv()
IO.inspect(Day15.solve(filepath))
