defmodule Day6 do
  def predict_next_position(lines, previous \\ ?.) do
    guard_still_on_map? =
      Enum.any?(lines, fn line -> String.contains?(line, ["^", "<", ">", "v"]) end)

    case guard_still_on_map? do
      false ->
        lines

      true ->
        with {new_lines, previous_char} <- move_guard(lines, previous) do
          predict_next_position(new_lines, previous_char)
        end
    end
  end

  defp move_guard(lines, previous) do
    result =
      lines
      |> Enum.chunk_every(3, 3)
      |> Enum.reduce({:not_found, [], previous}, &Day6.check_and_maybe_modify_chunk/2)

    {status, new_lines, new_previous} =
      case result do
        :cycle_detected ->
          {:cycle_detected, 0, 0}

        {:found, _, _} ->
          result

        {:not_found, _, _} ->
          [head2 | second_lines] = lines

          result =
            second_lines
            |> Enum.chunk_every(3, 3)
            |> Enum.reduce({:not_found, [], previous}, &Day6.check_and_maybe_modify_chunk/2)

          case result do
            :cycle_detected ->
              {:cycle_detected, 0, 0}

            {:found, found_in_lines, new_previous} ->
              {:found, [head2] ++ found_in_lines, new_previous}

            {:not_found, _, _} ->
              [head3 | third_lines] = second_lines

              result =
                third_lines
                |> Enum.chunk_every(3, 3)
                |> Enum.reduce({:not_found, [], previous}, &Day6.check_and_maybe_modify_chunk/2)

              case result do
                :cycle_detected ->
                  {:cycle_detected, 0, 0}

                {:found, found_in_lines, new_previous} ->
                  {:found, [head2, head3] ++ found_in_lines, new_previous}

                {:not_found, _, _} ->
                  result
              end
          end
      end

    case status do
      :cycle_detected ->
        :cycle_detected

      :found ->
        {new_lines, new_previous}

      :not_found ->
        [line1, line2 | rest_of_lines] = lines
        guard_in_line1? = String.contains?(line1, ["^", "<", ">", "v"])
        length = String.length(line1)
        padding = String.duplicate("X", length)

        case guard_in_line1? do
          true ->
            with {[_, line1, line2], new_previous} <-
                   modify_chunk([padding, line1, line2], previous) do
              {[line1, line2 | rest_of_lines], new_previous}
            end

          false ->
            ## then it must be in the last two lines
            [last, second_last | rest_of_lines_reversed] = Enum.reverse(lines)

            with {[second_last, last, _], new_previous} <-
                   modify_chunk([second_last, last, padding], previous) do
              {Enum.reverse([last, second_last | rest_of_lines_reversed]), new_previous}
            end
        end
    end
  end

  def check_and_maybe_modify_chunk(chunk, {:found, previous_lines, previous_char}),
    do: {:found, previous_lines ++ chunk, previous_char}

  def check_and_maybe_modify_chunk([], {:not_found, previous_lines, previous_char}),
    do: {:not_found, previous_lines, previous_char}

  def check_and_maybe_modify_chunk([el], {:not_found, previous_lines, previous_char}),
    do: {:not_found, previous_lines ++ [el], previous_char}

  def check_and_maybe_modify_chunk([el1, el2], {:not_found, previous_lines, previous_char}),
    do: {:not_found, previous_lines ++ [el1, el2], previous_char}

  def check_and_maybe_modify_chunk(
        [_, line2, _] = chunk,
        {:not_found, previous_lines, previous_char}
      ) do
    guard_in_chunk? = String.contains?(line2, ["^", "<", ">", "v"])

    case guard_in_chunk? do
      false ->
        {:not_found, previous_lines ++ chunk, previous_char}

      true ->
        # todo modify lines, then append to previous lines

        with {modified_lines, previous_char} <- modify_chunk(chunk, previous_char) do
          {:found, previous_lines ++ modified_lines, previous_char}
        end
    end
  end

  defp modify_chunk([line1, line2, line3], previously) do
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

    case guard do
      ?< ->
        char_to_the_left = line2_chars |> Enum.at(guard_index - 1)

        case char_to_the_left do
          # move up, place X
          ?# ->
            {chars_to_the_left, [_guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            # always "+" because its a corner
            filler = ?+

            line2_chars = chars_to_the_left ++ [filler] ++ chars_to_the_right

            {chars_to_the_left, [previous_char | chars_to_the_right]} =
              Enum.split(line1_chars, guard_index)

            line1_chars = chars_to_the_left ++ [?^] ++ chars_to_the_right

            # new chunk
            case previous_char do
              x when x in [?|, ?+] ->
                :cycle_detected

              _ ->
                {[List.to_string(line1_chars), List.to_string(line2_chars), line3], previous_char}
            end

          # move of the map, place x
          nil ->
            [_ | line2_chars] = line2_chars

            filler =
              case previously do
                ?. -> ?-
                ?- -> ?-
                ?| -> ?+
                ?+ -> ?+
              end

            line2_chars = [filler] ++ line2_chars

            # new chunk
            {[line1, List.to_string(line2_chars), line3], nil}

          # move left, place x
          _ ->
            {chars_to_the_left, [previous_char, _guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index - 1)

            filler =
              case previously do
                ?. -> ?-
                ?- -> ?-
                ?| -> ?+
                ?+ -> ?+
              end

            line2_chars = chars_to_the_left ++ [?<, filler] ++ chars_to_the_right

            case previous_char do
              x when x in [?-, ?+] ->
                :cycle_detected

              _ ->
                {[line1, List.to_string(line2_chars), line3], previous_char}
            end

            # new chunk
        end

      ?> ->
        char_to_the_right = line2_chars |> Enum.at(guard_index + 1)

        case char_to_the_right do
          # move down, place X
          ?# ->
            {chars_to_the_left, [_guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            filler = ?+

            line2_chars = chars_to_the_left ++ [filler] ++ chars_to_the_right

            {chars_to_the_left, [previous_char | chars_to_the_right]} =
              Enum.split(line3_chars, guard_index)

            line3_chars = chars_to_the_left ++ [?v] ++ chars_to_the_right

            # new chunk
            case previous_char do
              x when x in [?|, ?+] ->
                :cycle_detected

              _ ->
                {[line1, List.to_string(line2_chars), List.to_string(line3_chars)], previous_char}
            end

          # move off the map, place x
          nil ->
            [_ | line2_chars] = Enum.reverse(line2_chars)

            filler =
              case previously do
                ?. -> ?-
                ?- -> ?-
                ?| -> ?+
                ?+ -> ?+
              end

            line2_chars = Enum.reverse([filler] ++ line2_chars)

            # new chunk
            {[line1, List.to_string(line2_chars), line3], nil}

          # move right, place x
          _ ->
            {chars_to_the_left, [_guard, previous_char | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            filler =
              case previously do
                ?. -> ?-
                ?- -> ?-
                ?| -> ?+
                ?+ -> ?+
              end

            line2_chars = chars_to_the_left ++ [filler, ?>] ++ chars_to_the_right

            case previous_char do
              x when x in [?-, ?+] ->
                :cycle_detected

              _ ->
                # new chunk
                {[line1, List.to_string(line2_chars), line3], previous_char}
            end
        end

      ?^ ->
        char_to_the_top = line1_chars |> Enum.at(guard_index)

        case char_to_the_top do
          # move right, place X
          ?# ->
            {chars_to_the_left, [_guard, previous_char | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            filler = ?+

            line2_chars = chars_to_the_left ++ [filler, ?>] ++ chars_to_the_right

            case previous_char do
              x when x in [?-, ?+] ->
                :cycle_detected

              _ ->
                {[line1, List.to_string(line2_chars), line3], previous_char}
            end

          # move up, place x
          _ ->
            {chars_to_the_left, [_guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            filler =
              case previously do
                ?. -> ?|
                ?| -> ?|
                ?- -> ?+
                ?+ -> ?+
              end

            line2_chars = chars_to_the_left ++ [filler] ++ chars_to_the_right

            {chars_to_the_left, [previous_char | chars_to_the_right]} =
              Enum.split(line1_chars, guard_index)

            line1_chars = chars_to_the_left ++ [?^] ++ chars_to_the_right

            case previous_char do
              x when x in [?|, ?+] ->
                :cycle_detected

              _ ->
                {[List.to_string(line1_chars), List.to_string(line2_chars), line3], previous_char}
            end
        end

      ?v ->
        char_to_the_bottom = line3_chars |> Enum.at(guard_index)

        case char_to_the_bottom do
          # move left, place X
          ?# ->
            {chars_to_the_left, [previous_char, _guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index - 1)

            filler = ?+

            line2_chars = chars_to_the_left ++ [?<, filler] ++ chars_to_the_right

            case previous_char do
              x when x in [?-, ?+] ->
                :cycle_detected

              _ ->
                {[line1, List.to_string(line2_chars), line3], previous_char}
            end

          # move down, place x
          _ ->
            {chars_to_the_left, [_guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            filler =
              case previously do
                ?. -> ?|
                ?| -> ?|
                ?- -> ?+
                ?+ -> ?+
              end

            line2_chars = chars_to_the_left ++ [filler] ++ chars_to_the_right

            {chars_to_the_left, [previous_char | chars_to_the_right]} =
              Enum.split(line3_chars, guard_index)

            line3_chars = chars_to_the_left ++ [?v] ++ chars_to_the_right

            case previous_char do
              x when x in [?|, ?+] ->
                :cycle_detected

              _ ->
                {[line1, List.to_string(line2_chars), List.to_string(line3_chars)], previous_char}
            end
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

# todo along each tile, place an x, check if it creates a cycle
