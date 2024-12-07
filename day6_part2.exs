defmodule Day6 do
  def predict_next_position(lines, previous \\ ?., movement_info \\ %{}) do
    guard_still_on_map? =
      Enum.any?(lines, fn line -> String.contains?(line, ["^", "<", ">", "v"]) end)

    case guard_still_on_map? do
      false ->
   #      IO.puts("\nvvvvvvvvv\n")
    #     IO.puts(lines |> Enum.reduce(fn line, c -> c <> "\n" <> line end))
     #    IO.puts("\n")
        lines

      true ->
       # IO.puts("\nvvvvvvvvv\n")
       # IO.puts(lines |> Enum.reduce(fn line, c -> c <> "\n" <> line end))
       # IO.puts("\n")
       case move_guard(lines, previous, movement_info) do
          {new_lines, previous_char, movement_info} ->
            predict_next_position(new_lines, previous_char, movement_info)

          :invalid_state ->
        #    IO.puts("invalid state...")
            :invalid_state

          :cycle_detected ->
       #     IO.puts("\nnnnnnnn\n")
       #     IO.inspect(movement_info)
        #    IO.puts(lines |> Enum.reduce(fn line, c -> c <> "\n" <> line end))
         #   IO.puts("\n")

            :cycle_detected
        end
    end
  end

  defp move_guard(lines, previous, %{} = movement_info) do
    result =
      lines
      |> Enum.chunk_every(3, 3)
      |> Enum.reduce(
        {:not_found, [], previous, 0, movement_info},
        &Day6.check_and_maybe_modify_chunk/2
      )

    {status, new_lines, new_previous, movement_info} =
      case result do
        {:found, _, _, _} ->
          result

        :invalid_state ->
          {:invalid_state, lines, previous, movement_info}

        :cycle_detected ->
          {:cycle_detected, lines, previous, movement_info}

        {:not_found, _, _, _, _} ->
          [head2 | second_lines] = lines

          result =
            second_lines
            |> Enum.chunk_every(3, 3)
            |> Enum.reduce(
              {:not_found, [], previous, 1, movement_info},
              &Day6.check_and_maybe_modify_chunk/2
            )

          case result do
            :invalid_state ->
              {:invalid_state, lines, previous, movement_info}

            :cycle_detected ->
              {:cycle_detected, lines, previous, movement_info}

            {:found, found_in_lines, new_previous, movement_info} ->
              {:found, [head2] ++ found_in_lines, new_previous, movement_info}

            {:not_found, _, _, _, _} ->
              [head3 | third_lines] = second_lines

              result =
                third_lines
                |> Enum.chunk_every(3, 3)
                |> Enum.reduce(
                  {:not_found, [], previous, 2, movement_info},
                  &Day6.check_and_maybe_modify_chunk/2
                )

              case result do
                :invalid_state ->
                  {:invalid_state, [], previous, movement_info}

                :cycle_detected ->
                  {:cycle_detected, [], previous, movement_info}

                {:found, found_in_lines, new_previous, movement_info} ->
                  {:found, [head2, head3] ++ found_in_lines, new_previous, movement_info}

                {:not_found, lines, previous, _, movement_info} ->
                  {:not_found, lines, previous, movement_info}
              end
          end
      end

    case status do
      :invalid_state ->
        :invalid_state

      :cycle_detected ->
        :cycle_detected

      :found ->
        {new_lines, new_previous, movement_info}

      :not_found ->
        [line1, line2 | rest_of_lines] = lines
        guard_in_line1? = String.contains?(line1, ["^", "<", ">", "v"])
        length = String.length(line1)
        padding = String.duplicate(".", length)

        case guard_in_line1? do
          true ->
            case modify_chunk([padding, line1, line2], previous, 0, movement_info) do
              {[_, line1, line2], new_previous, movement_info} ->
                {[line1, line2 | rest_of_lines], new_previous, movement_info}

              :cycle_detected ->
                :cycle_detected

              :invalid_state ->
                :invalid_state
            end

          false ->
            ## then it must be in the last two lines
            count = Enum.count(lines)
            [last, second_last | rest_of_lines_reversed] = Enum.reverse(lines)

            case modify_chunk([second_last, last, padding], previous, count - 1, movement_info) do
              {[second_last, last, _], new_previous, movement_info} ->
                {Enum.reverse([last, second_last | rest_of_lines_reversed]), new_previous,
                 movement_info}

              :cycle_detected ->
                :cycle_detected

              :invalid_state ->
                :invalid_state
            end
        end
    end
  end

  def check_and_maybe_modify_chunk(chunk, :cycle_detected),
    do: :cycle_detected

  def check_and_maybe_modify_chunk(chunk, :invalid_state),
    do: :invalid_state

  def check_and_maybe_modify_chunk(
        chunk,
        {:found, previous_lines, previous_char, _, movement_info}
      ),
      do: {:found, previous_lines ++ chunk, previous_char, movement_info}

  def check_and_maybe_modify_chunk(
        chunk,
        {:found, previous_lines, previous_char, movement_info}
      ),
      do: {:found, previous_lines ++ chunk, previous_char, movement_info}

  def check_and_maybe_modify_chunk(
        [],
        {:not_found, previous_lines, previous_char, chunk_index, movement_info}
      ),
      do: {:not_found, previous_lines, previous_char, chunk_index, movement_info}

  def check_and_maybe_modify_chunk(
        [line1],
        {:not_found, previous_lines, previous_char, chunk_index, movement_info}
      ),
      do: {:not_found, previous_lines ++ [line1], previous_char, chunk_index, movement_info}

  def check_and_maybe_modify_chunk(
        [line1, line2],
        {:not_found, previous_lines, previous_char, chunk_index, movement_info}
      ),
      do:
        {:not_found, previous_lines ++ [line1, line2], previous_char, chunk_index, movement_info}

  def check_and_maybe_modify_chunk(
        [_, line2, _] = chunk,
        {:not_found, previous_lines, previous_char, chunk_index, movement_info}
      ) do
    guard_in_chunk? = String.contains?(line2, ["^", "<", ">", "v"])

    case guard_in_chunk? do
      false ->
        {:not_found, previous_lines ++ chunk, previous_char, chunk_index + 3, movement_info}

      true ->
        # todo modify lines, then append to previous lines

        result = modify_chunk(chunk, previous_char, chunk_index + 1, movement_info)

        case result do
          {modified_lines, previous_char, movement_info} ->
            {:found, previous_lines ++ modified_lines, previous_char, movement_info}

          _ ->
            result
        end
    end
  end

  defp modify_chunk([line1, line2, line3], previously, absolute_line_index, movement_info) do
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
        i = guard_index - 1

        char_to_the_left =
          case i do
            i when i >= 0 -> line2_chars |> Enum.at(guard_index - 1)
            _ -> nil
          end

        case char_to_the_left do
          # move up
          c when c in [?#, ?O] ->
            {chars_to_the_left, [_guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            # always "+" because its a corner
            filler = ?+

            line2_chars = chars_to_the_left ++ [filler] ++ chars_to_the_right

            {chars_to_the_left, [previous_char | chars_to_the_right]} =
              Enum.split(line1_chars, guard_index)

            line1_chars = chars_to_the_left ++ [?^] ++ chars_to_the_right

            directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

            case Enum.member?(directions, "up") do
              true ->
                :cycle_detected

              false ->
                movement_info =
                  Map.put(movement_info, {absolute_line_index, guard_index}, ["up" | directions])

                  case previous_char do
                    # to the right is also a wall...
                    x when x in [?#, ?O] ->
                      :invalid_state

                      # new chunk
                  _ ->
                    {[List.to_string(line1_chars), List.to_string(line2_chars), line3],
                     previous_char, movement_info}
                end
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
            {[line1, List.to_string(line2_chars), line3], nil, movement_info}

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

            directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

            case Enum.member?(directions, "left") do
              true ->
                :cycle_detected

              false ->
                movement_info =
                  Map.put(movement_info, {absolute_line_index, guard_index}, ["left" | directions])

                # new chunk
                case previous_char do
                  x when x in [?#, ?O] ->
                    :invalid_state

                  _ ->
                    {[line1, List.to_string(line2_chars), line3], previous_char, movement_info}
                end
            end
        end

      ?> ->
        char_to_the_right = line2_chars |> Enum.at(guard_index + 1)

        case char_to_the_right do
          # move down, place X
          c when c in [?#, ?O] ->
            {chars_to_the_left, [_guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            filler = ?+

            line2_chars = chars_to_the_left ++ [filler] ++ chars_to_the_right

            {chars_to_the_left, [previous_char | chars_to_the_right]} =
              Enum.split(line3_chars, guard_index)

            line3_chars = chars_to_the_left ++ [?v] ++ chars_to_the_right

            directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

            case Enum.member?(directions, "down") do
              true ->
                :cycle_detected

              false ->
                movement_info =
                  Map.put(movement_info, {absolute_line_index, guard_index}, ["down" | directions])

                # new chunk
                case previous_char do
                  x when x in [?#, ?O] ->
                    :invalid_state

                  _ ->
                    {[line1, List.to_string(line2_chars), List.to_string(line3_chars)],
                     previous_char, movement_info}
                end
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
            {[line1, List.to_string(line2_chars), line3], nil, movement_info}

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
            directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

            case Enum.member?(directions, "right") do
              true ->
                :cycle_detected

              false ->
                movement_info =
                  Map.put(movement_info, {absolute_line_index, guard_index}, [
                    "right" | directions
                  ])

                case previous_char do
                  x when x in [?#, ?O] ->
                    :invalid_state

                  _ ->
                    # new chunk
                    {[line1, List.to_string(line2_chars), line3], previous_char, movement_info}
                end
            end
        end

      ?^ ->
        char_to_the_top = line1_chars |> Enum.at(guard_index)

        case char_to_the_top do
          # move right, place X
          c when c in [?#, ?O] ->
            {chars_to_the_left, [_guard, previous_char | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index)

            filler = ?+

            line2_chars = chars_to_the_left ++ [filler, ?>] ++ chars_to_the_right
            directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

            case Enum.member?(directions, "right") do
              true ->
                :cycle_detected

              false ->
                movement_info =
                  Map.put(movement_info, {absolute_line_index, guard_index}, [
                    "right" | directions
                  ])

                case previous_char do
                  x when x in [?#, ?O] ->
                    :invalid_state

                  _ ->
                    {[line1, List.to_string(line2_chars), line3], previous_char, movement_info}
                end
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
            directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

            case Enum.member?(directions, "up") do
              true ->
                :cycle_detected

              false ->
                movement_info =
                  Map.put(movement_info, {absolute_line_index, guard_index}, ["up" | directions])

                case previous_char do
                  x when x in [?#, ?O] ->
                    :invalid_state

                  _ ->
                    {[List.to_string(line1_chars), List.to_string(line2_chars), line3],
                     previous_char, movement_info}
                end
            end
        end

      ?v ->
        char_to_the_bottom = line3_chars |> Enum.at(guard_index)

        case char_to_the_bottom do
          # move left, place X
          c when c in [?#, ?O] ->
            {chars_to_the_left, [previous_char, _guard | chars_to_the_right]} =
              Enum.split(line2_chars, guard_index - 1)

            filler = ?+

            line2_chars = chars_to_the_left ++ [?<, filler] ++ chars_to_the_right
            directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

            case Enum.member?(directions, "left") do
              true ->
                :cycle_detected

              false ->
                movement_info =
                  Map.put(movement_info, {absolute_line_index, guard_index}, ["left" | directions])

                case previous_char do
                  x when x in [?#, ?O] ->
                    :invalid_state

                  _ ->
                    {[line1, List.to_string(line2_chars), line3], previous_char, movement_info}
                end
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
            directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

            case Enum.member?(directions, "down") do
              true ->
                :cycle_detected

              false ->
                movement_info =
                  Map.put(movement_info, {absolute_line_index, guard_index}, ["down" | directions])

                case previous_char do
                  x when x in [?#, ?O] ->
                    :invalid_state

                  _ ->
                    {[line1, List.to_string(line2_chars), List.to_string(line3_chars)],
                     previous_char, movement_info}
                end
            end
        end
    end
  end

  def create_alterations(original_map, line, row_index) do
    ## create new list of alterior maps
    ## todo check for indexes of possible alterations (+ - | indexes) in original map in line row_index

    {column_indexes, _} =
      line
      |> String.to_charlist()
      |> Enum.reduce({[], -1}, fn char, {indexes, counter} ->
        counter = counter + 1

        case char do
          c when c in [?+, ?-, ?|] -> {[counter] ++ indexes, counter}
          _ -> {indexes, counter}
        end
      end)

    column_indexes
    |> Enum.reduce([], fn column_index, map_alterations ->
      {before_lines, [current_line | after_lines]} = original_map |> Enum.split(row_index)

      {before_chars, [_ | after_chars]} =
        current_line
        |> String.to_charlist()
        |> Enum.split(column_index)

      current_line =
        (before_chars ++ [?O] ++ after_chars)
        |> List.to_string()

      alteration = before_lines ++ [current_line] ++ after_lines

      [alteration | map_alterations]
    end)
  end
end

original_map =
  File.stream!("day6.data", :line)
  |> Enum.map(&String.trim/1)

IO.puts(original_map |> Enum.reduce(fn line, c -> c <> "\n" <> line end))

map =
  original_map
  |> Day6.predict_next_position()

IO.puts("\nvvvvvvvvv\n")
IO.puts("  SOLVED \n")
IO.puts("vvvvvvvvv\n")
IO.puts(map |> Enum.reduce(fn line, c -> c <> "\n" <> line end))

IO.puts("\nvvvvvvvvv\n")
IO.puts("\nvvvvvvvvv\n")
IO.puts("\nvvvvvvvvv\n")
IO.puts("\nvvvvvvvvv\n")

# todo along each tile, place an x, check if it creates a cycle

map_variations_with_new_obstacle =
  map
  |> Enum.reduce({[], 0}, fn line, {container, row_index} ->
    can_be_altered? = String.contains?(line, ["+", "-", "|"])

    case can_be_altered? do
      false ->
        {container, row_index + 1}

      true ->
        alterations = Day6.create_alterations(original_map, line, row_index)

        {alterations ++ container, row_index + 1}
    end
  end)
  |> elem(0)

IO.puts("Looking at the variant! vvvvvv")
IO.inspect(map_variations_with_new_obstacle |> Enum.count())

count_of_loops =
  map_variations_with_new_obstacle
  |> Enum.map(fn variant -> Task.async(fn ->
    result = Day6.predict_next_position(variant)
    result
  end) end)
  |> Enum.map(fn task -> Task.await(task, :infinity) end)
  |> Enum.filter(fn result ->result == :cycle_detected end)
  # |>List.first()
  # |> List.duplicate(1)
  # |> Enum.map(fn {map, _} ->
  #   IO.puts("\n==========\n")
  #   IO.puts(map |> Enum.reduce(fn line, c -> c <> "\n" <> line end))
  # end)
  |> Enum.count()

IO.inspect("Found loops:")
IO.inspect(count_of_loops)
