defmodule Day6 do
  def predict_next_position(lines) do
    guard_still_on_map? =
      Enum.any?(lines, fn line -> String.contains?(line, ["^", "<", ">", "v"]) end)

    case guard_still_on_map? do
      false ->
        lines

      true ->
        # todo move guard, leave behind X in its path
        lines
        |> move_guard()
        |> predict_next_position()
    end
  end

  defp move_guard(lines) do
    # move through the lines, search in the middle line for the guard
    # -> {:found, modified_lines (all seen so far, + modified + the rest of the lines)} -> {:not_found, lines}
    # go through 3 lines, step 3,  3 times. 1. offset = 0, 2. offset = 1, 3. offset = 2 until we found the guard in any of em.

    # very first and very last line as special cases extra

    result =
      lines
      |> Enum.chunk_every(3, 3)
      |> Enum.reduce({:not_found, []}, &Day6.check_and_maybe_modify_chunk/2)

    {status, new_lines} =
      case result do
        {:found, _} ->
          result

        {:not_found, _} ->
          [head2 | second_lines] = lines

          result =
            second_lines
            |> Enum.chunk_every(3, 3)
            |> Enum.reduce({:not_found, []}, &Day6.check_and_maybe_modify_chunk/2)

          case result do
            {:found, found_in_lines} ->
              {:found, [head2] ++ found_in_lines}

            {:not_found, _} ->
              [head3 | third_lines] = second_lines

              result =
                third_lines
                |> Enum.chunk_every(3, 3)
                |> Enum.reduce({:not_found, []}, &Day6.check_and_maybe_modify_chunk/2)

              case result do
                {:found, found_in_lines} -> {:found, [head2, head3] ++ found_in_lines}
                {:not_found, _} -> result
              end
          end
      end

    case status do
      :found ->
        new_lines

      :not_found ->
        [line1, line2 | rest_of_lines] = lines
        guard_in_line1? = String.contains?(line1, ["^", "<", ">", "v"])
        length = String.length(line1)
        padding = String.duplicate("X", length)

        case guard_in_line1? do
          true ->
            [_, line1, line2] = modify_chunk([padding, line1, line2])
            [line1, line2 | rest_of_lines]

          false ->
            ## then it must be in the last two lines
            [last, second_last | rest_of_lines_reversed] = Enum.reverse(lines)

            [second_last, last, _] = modify_chunk([second_last, last, padding])
            Enum.reverse([last, second_last | rest_of_lines_reversed])
        end
    end
  end

  def check_and_maybe_modify_chunk(chunk, {:found, previous_lines}) do
    {:found, previous_lines ++ chunk}
  end

  def check_and_maybe_modify_chunk([], {:not_found, previous_lines}),
    do: {:not_found, previous_lines}

  def check_and_maybe_modify_chunk([el], {:not_found, previous_lines}),
    do: {:not_found, previous_lines ++ [el]}

  def check_and_maybe_modify_chunk([el1, el2], {:not_found, previous_lines}),
    do: {:not_found, previous_lines ++ [el1, el2]}

  def check_and_maybe_modify_chunk([_, line2, _] = chunk, {:not_found, previous_lines}) do
    guard_in_chunk? = String.contains?(line2, ["^", "<", ">", "v"])

    case guard_in_chunk? do
      false ->
        {:not_found, previous_lines ++ chunk}

      true ->
        # todo modify lines, then append to previous lines

        modified_lines = modify_chunk(chunk)

        {:found, previous_lines ++ modified_lines}
    end
  end

  defp modify_chunk([line1, line2, line3]) do
    # find guard char
    line1_chars = String.to_charlist(line1)
    line2_chars = String.to_charlist(line2)
    line3_chars = String.to_charlist(line3)

    guard =
      case line2_chars |> Enum.find(fn c -> c == ?^ end) do
        ?^ ->
          ?^

        nil ->
          case line2_chars |> Enum.find(fn c -> c == ?< end) do
            ?< ->
              ?<

            nil ->
              case line2_chars |> Enum.find(fn c -> c == ?> end) do
                ?> -> ?>
                nil -> ?v
              end
          end
      end

    guard_index = Enum.find_index(line2_chars, fn c -> c == guard end)

    # check what direction the guard is looking
    # check where they move next -> check for #'s in their way
    # replace the guard with an X in the string
    # replace the character for the next position with the guards char
    case guard do
      ?< ->
        char_to_the_left = line2_chars |> Enum.at(guard_index - 1)

        case char_to_the_left do
          # move up, place X
          ?# ->
            {chars_to_the_left, [_guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            line2_chars = chars_to_the_left ++ [?X] ++ chars_to_the_right

            {chars_to_the_left, [_ | chars_to_the_right]} = Enum.split(line1_chars, guard_index)
            line1_chars = chars_to_the_left ++ [?^] ++ chars_to_the_right

            # new chunk
            [List.to_string(line1_chars), List.to_string(line2_chars), line3]

          # move of the map, place x
          nil ->
            [_ | line2_chars] = line2_chars
            line2_chars = [?X] ++ line2_chars

            # new chunk
            [line1, List.to_string(line2_chars), line3]

          # move left, place x
          _ ->
            {chars_to_the_left, [_, _guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index - 1)

            line2_chars = chars_to_the_left ++ [?<, ?X] ++ chars_to_the_right

            # new chunk
            [line1, List.to_string(line2_chars), line3]
        end

      ?> ->
        char_to_the_right = line2_chars |> Enum.at(guard_index + 1)

        case char_to_the_right do
          # move down, place X
          ?# ->
            {chars_to_the_left, [_guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            line2_chars = chars_to_the_left ++ [?X] ++ chars_to_the_right

            {chars_to_the_left, [_ | chars_to_the_right]} = Enum.split(line3_chars, guard_index)
            line3_chars = chars_to_the_left ++ [?v] ++ chars_to_the_right

            # new chunk
            [line1, List.to_string(line2_chars), List.to_string(line3_chars)]

          # move off the map, place x
          nil ->
            [_ | line2_chars] = Enum.reverse(line2_chars)
            line2_chars = Enum.reverse([?X] ++ line2_chars)

            # new chunk
            [line1, List.to_string(line2_chars), line3]

          # move right, place x
          _ ->
            {chars_to_the_left, [_guard, _ | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            line2_chars = chars_to_the_left ++ [?X, ?>] ++ chars_to_the_right

            # new chunk
            [line1, List.to_string(line2_chars), line3]
        end

      ?^ ->
        char_to_the_top = line1_chars |> Enum.at(guard_index)

        case char_to_the_top do
          # move right, place X
          ?# ->
            {chars_to_the_left, [_guard, _ | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            line2_chars = chars_to_the_left ++ [?X, ?>] ++ chars_to_the_right

            [line1, List.to_string(line2_chars), line3]

          # move up, place x
          _ ->
            {chars_to_the_left, [_guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            line2_chars = chars_to_the_left ++ [?X] ++ chars_to_the_right

            {chars_to_the_left, [_ | chars_to_the_right]} = Enum.split(line1_chars, guard_index)
            line1_chars = chars_to_the_left ++ [?^] ++ chars_to_the_right

            [List.to_string(line1_chars), List.to_string(line2_chars), line3]
        end

      ?v ->
        char_to_the_bottom = line3_chars |> Enum.at(guard_index)

        case char_to_the_bottom do
          # move left, place X
          ?# ->
            {chars_to_the_left, [_, _guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index - 1)

            line2_chars = chars_to_the_left ++ [?<, ?X] ++ chars_to_the_right

            [line1, List.to_string(line2_chars), line3]

          # move down, place x
          _ ->
            {chars_to_the_left, [_guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            line2_chars = chars_to_the_left ++ [?X] ++ chars_to_the_right

            {chars_to_the_left, [_ | chars_to_the_right]} = Enum.split(line3_chars, guard_index)
            line3_chars = chars_to_the_left ++ [?v] ++ chars_to_the_right

            [line1, List.to_string(line2_chars), List.to_string(line3_chars)]
        end
    end
  end
end

map =
  File.stream!("day6.data", :line)
  |> Enum.map(&String.trim/1)

IO.puts(map |> Enum.reduce(fn line, c -> c <> "\n" <> line end))

map =
  map
  |> Day6.predict_next_position()

IO.puts("\nvvvvvvvvv\n")
IO.puts(map |> Enum.reduce(fn line, c -> c <> "\n" <> line end))

count =
  map
  |> Enum.reduce(0, fn line, acc ->
    x_count =
      String.to_charlist(line)
      |> Enum.filter(fn char -> char == ?X end)
      |> Enum.count()

    acc + x_count
  end)

IO.inspect(count)
