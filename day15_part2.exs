defmodule Day15 do
  def solve(filepath) do
    {map, robot_position, commands} =
      File.stream!(filepath, :line)
      |> parse_map()

    IO.puts("=====")
    draw_map(map)

    {updated_map, _} = move_robot(map, robot_position, commands)

    IO.puts("=====")
    draw_map(updated_map)

    calculate_gps_cost(updated_map)
  end

  defp calculate_gps_cost(map) do
    [box] = String.to_charlist("[")

    Map.keys(map)
    |> Enum.reduce(0, fn {x, y} = key, sum ->
      char = map[key]

      case char do
        ^box ->
          sum + x + 100 * y

        _ ->
          sum
      end
    end)
  end

  defp draw_map(map, hightlight \\ {-1, -1}) do
    keys = Map.keys(map)

    max_x = keys |> Enum.map(fn {x, _} -> x end) |> Enum.max()
    max_y = keys |> Enum.map(fn {_, y} -> y end) |> Enum.max()

    lines =
      0..max_y
      |> Enum.map(fn y ->
        0..max_x
        |> Enum.map(fn x ->
          s = List.to_string([map[{x, y}]])

          case {x, y} do
            ^hightlight -> "\e[31;1;4m" <> s <> "\e[0m"
            _ -> s
          end
        end)
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

    draw_map(map)
    move_robot(map, robot_position, commands)
  end

  defp move_direction(map, {x, y} = tile, direction) when direction in [:up, :down] do
    next_char_position =
      case direction do
        :up -> {x, y - 1}
        :down -> {x, y + 1}
      end

    [l, r] = String.to_charlist("[]")
    # try to make space for the robot
    next_char = map[next_char_position]
    char = Map.get(map, tile)

    IO.inspect({"looking at", tile, "going", direction})
    IO.inspect({"char", [char], "next char", [next_char]})
    draw_map(map, tile)

    case char do
      char when char in [?., ?#] ->
        {map, tile}

      ?@ ->
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
            # so try to make space
            {updated_map, _} = move_direction(map, next_char_position, direction)
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

      ^l ->
        {nx, ny} = next_char_position
        next_char_l = map[next_char_position]
        next_char_r = map[{nx + 1, ny}]

        {updated_map, pos} =
          case {next_char_l, next_char_r} do
            {nil, _} ->
              # out of bounds
              {map, tile}

            {_, nil} ->
              {map, tile}

            {?#, _} ->
              # wall
              {map, tile}

            {_, ?#} ->
              # wall
              {map, tile}

            {?., ?.} ->
              # empty space
              # so move into empty tile
              {map
               |> Map.put({x, y}, ?.)
               |> Map.put({x + 1, y}, ?.)
               |> Map.put({nx, ny}, l)
               |> Map.put({nx + 1, ny}, r), next_char_position}

            {^r, ^l} ->
              # move both boxes
              # move both boxes
              # check ob ich eins bewegen kann => wird zu .
              {updated_map, _} = move_direction(map, next_char_position, direction)

              case updated_map[next_char_position] do
                ?. ->
                  # wenn ja, dann bewege das andere
                  # falls ich das nicht bewegen kann, ursprüngliche map zurückgeben
                  # sonst die bearbeitete
                  {updated_map, pos} = move_direction(updated_map, {nx + 1, ny}, direction)

                  case updated_map[{nx + 1, ny}] do
                    ?. -> {updated_map, pos}
                    _ -> {map, next_char_position}
                  end

                _ ->
                  {map, next_char_position}
              end

            {^l, ^r} ->
              move_direction(map, next_char_position, direction)

            {^r, ?.} ->
              # move left boxes
              move_direction(map, next_char_position, direction)

            {?., ^l} ->
              # move left boxes
              move_direction(map, {nx + 1, ny}, direction)
          end

        next_char_l = updated_map[next_char_position]
        next_char_r = updated_map[{nx + 1, ny}]

        case {next_char_l, next_char_r} do
          {?., ?.} ->
            {updated_map
             |> Map.put({x, y}, ?.)
             |> Map.put({x + 1, y}, ?.)
             |> Map.put({nx, ny}, l)
             |> Map.put({nx + 1, ny}, r), pos}

          _ ->
            {updated_map, pos}
        end

      ^r ->
        {nx, ny} = next_char_position
        next_char_l = map[{nx - 1, ny}]
        next_char_r = map[next_char_position]

        {updated_map, pos} =
          case {next_char_l, next_char_r} do
            {nil, _} ->
              # out of bounds
              {map, tile}

            {_, nil} ->
              {map, tile}

            {?#, _} ->
              # wall
              {map, tile}

            {_, ?#} ->
              # wall
              {map, tile}

            {?., ?.} ->
              # empty space
              # so move into empty tile

              {map
               |> Map.put({x, y}, ?.)
               |> Map.put({x - 1, y}, ?.)
               |> Map.put({nx, ny}, r)
               |> Map.put({nx - 1, ny}, l), next_char_position}

            {^r, ^l} ->
              # move both boxes
              # check ob ich eins bewegen kann => wird zu .
              {updated_map, _} = move_direction(map, next_char_position, direction)

              case updated_map[next_char_position] do
                ?. ->
                  # wenn ja, dann bewege das andere
                  # falls ich das nicht bewegen kann, ursprüngliche map zurückgeben
                  # sonst die bearbeitete
                  {updated_map, pos} = move_direction(updated_map, {nx - 1, ny}, direction)

                  case updated_map[{nx - 1, ny}] do
                    ?. -> {updated_map, pos}
                    _ -> {map, tile}
                  end

                _ ->
                  {map, tile}
              end

            {^l, ^r} ->
              # move both boxes
              {updated_map, _} = move_direction(map, next_char_position, direction)

            {^r, ?.} ->
              # move left boxes
              move_direction(map, {nx - 1, ny}, direction)

            {?., ^l} ->
              # move left boxes
              move_direction(map, next_char_position, direction)
          end

        next_char_r = updated_map[next_char_position]
        next_char_l = updated_map[{nx - 1, ny}]

        case {next_char_l, next_char_r} do
          {?., ?.} ->
            {updated_map
             |> Map.put({x, y}, ?.)
             |> Map.put({x - 1, y}, ?.)
             |> Map.put({nx, ny}, r)
             |> Map.put({nx - 1, ny}, l), pos}

          _ ->
            {updated_map, pos}
        end
    end
  end

  defp move_direction(map, {x, y} = tile, direction) when direction in [:left, :right] do
    next_char_position =
      case direction do
        :left -> {x - 1, y}
        :right -> {x + 1, y}
      end

    # try to make space for the robot
    next_char = map[next_char_position]
    char = Map.get(map, tile)

    IO.inspect({"looking at", tile, "going", direction})
    IO.inspect({"char", [char], "next char", [next_char]})
    draw_map(map, tile)

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

                    m =
                      case char do
                        char when char in [?#, ?.] ->
                          m
                          |> Map.put({x, y}, char)
                          |> Map.put({x + 1, y}, char)

                        ?@ ->
                          m
                          |> Map.put({x, y}, char)
                          |> Map.put({x + 1, y}, ?.)

                        ?O ->
                          [first, second] = "[]" |> String.to_charlist()

                          m
                          |> Map.put({x, y}, first)
                          |> Map.put({x + 1, y}, second)
                      end

                    {m, r, x + 2}
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
