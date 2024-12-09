defmodule Day6 do
  def predict_next_position(lines, previous \\ ?., movement_info \\ %{}) do
    guard_still_on_map? =
      Enum.any?(lines, fn line -> String.contains?(line, ["^", "<", ">", "v"]) end)

    case guard_still_on_map? do
      false ->
        #      IO.puts("\nvvvvvvvvv\n")
        #     IO.puts(lines |> Enum.reduce(fn line, c -> c <> "\n" <> line end))
        #    IO.puts("\n")
        # IO.puts("END OF SIMULATION")
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
            #    IO.inspect(movement_info)
            #  IO.puts(lines |> Enum.reduce(fn line, c -> c <> "\n" <> line end))
            # IO.puts("\n")

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

  def check_and_maybe_modify_chunk(_chunk, :cycle_detected),
    do: :cycle_detected

  def check_and_maybe_modify_chunk(_chunk, :invalid_state),
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

  def find_guard_char(line2_chars) do
    case line2_chars |> Enum.member?(?^) do
      true ->
        ?^

      false ->
        case line2_chars |> Enum.member?(?<) do
          true ->
            ?<

          false ->
            case line2_chars |> Enum.member?(?>) do
              true -> ?>
              false -> ?v
            end
        end
    end
  end

  def modify_chunk([line1, line2, line3], previously, absolute_line_index, movement_info) do
    # find guard char
    line1_chars = String.to_charlist(line1)
    line2_chars = String.to_charlist(line2)
    line3_chars = String.to_charlist(line3)

    guard = find_guard_char(line2_chars)

    guard_index = Enum.find_index(line2_chars, fn c -> c == guard end)

    case guard do
      ?< ->
        move_left(
          absolute_line_index,
          guard_index,
          previously,
          movement_info,
          line1,
          line2,
          line3,
          line1_chars,
          line2_chars,
          line3_chars
        )

      ?> ->
        move_right(
          absolute_line_index,
          guard_index,
          previously,
          movement_info,
          line1,
          line2,
          line3,
          line1_chars,
          line2_chars,
          line3_chars
        )

      ?^ ->
        move_up(
          absolute_line_index,
          guard_index,
          previously,
          movement_info,
          line1,
          line2,
          line3,
          line1_chars,
          line2_chars,
          line3_chars
        )

      ?v ->
        move_down(
          absolute_line_index,
          guard_index,
          previously,
          movement_info,
          line1,
          line2,
          line3,
          line1_chars,
          line2_chars,
          line3_chars
        )
    end
  end

  def move_up(
        absolute_line_index,
        guard_index,
        previously,
        movement_info,
        line1,
        line2,
        line3,
        line1_chars,
        line2_chars,
        line3_chars
      ) do
    char_to_the_top = line1_chars |> Enum.at(guard_index)

    case char_to_the_top do
      # move right, place X
      c when c in [?#, ?O] ->
        {chars_to_the_left, [_guard, char_to_the_right | chars_to_the_right]} =
          Enum.split(line2_chars, guard_index)

        filler = ?+

        directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

        case Enum.member?(directions, "right") do
          true ->
            :cycle_detected

          false ->
            movement_info =
              Map.put(movement_info, {absolute_line_index, guard_index}, [
                "right" | directions
              ])

            case char_to_the_right do
              x when x in [?#, ?O] ->
                directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

                case Enum.member?(directions, "down") do
                  true ->
                    :cycle_detected

                  false ->
                    movement_info =
                      Map.put(movement_info, {absolute_line_index, guard_index}, [
                        "down" | directions
                      ])

                    line2_chars =
                      chars_to_the_left ++ [?+, char_to_the_right] ++ chars_to_the_right

                    {chars_to_the_left, [char_to_the_right | chars_to_the_right]} =
                      Enum.split(line3_chars, guard_index)

                    line3_chars = chars_to_the_left ++ [?v] ++ chars_to_the_right

                    {[line1, List.to_string(line2_chars), List.to_string(line3_chars)], ?+,
                     movement_info}
                end

              _ ->
                line2_chars = chars_to_the_left ++ [filler, ?>] ++ chars_to_the_right
                {[line1, List.to_string(line2_chars), line3], char_to_the_right, movement_info}
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
                {[List.to_string(line1_chars), List.to_string(line2_chars), line3], previous_char,
                 movement_info}
            end
        end
    end
  end

  def move_down(
        absolute_line_index,
        guard_index,
        previously,
        movement_info,
        line1,
        line2,
        line3,
        line1_chars,
        line2_chars,
        line3_chars
      ) do
    char_to_the_bottom = line3_chars |> Enum.at(guard_index)

    case char_to_the_bottom do
      # move left, place X
      c when c in [?#, ?O] ->
        {chars_to_the_left, [char_to_the_left, _guard | chars_to_the_right]} =
          Enum.split(line2_chars, guard_index - 1)

        directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

        case Enum.member?(directions, "left") do
          true ->
            :cycle_detected

          false ->
            movement_info =
              Map.put(movement_info, {absolute_line_index, guard_index}, ["left" | directions])

            case char_to_the_left do
              # turn around
              x when x in [?#, ?O] ->
                directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

                case Enum.member?(directions, "up") do
                  true ->
                    :cycle_detected

                  false ->
                    movement_info =
                      Map.put(movement_info, {absolute_line_index, guard_index}, [
                        "up" | directions
                      ])

                    line2_chars = chars_to_the_left ++ [?+, ?+] ++ chars_to_the_right

                    {chars_to_the_left, [previous_char | chars_to_the_right]} =
                      Enum.split(line1_chars, guard_index)

                    line1_chars = chars_to_the_left ++ [?^] ++ chars_to_the_right

                    {[List.to_string(line1_chars), List.to_string(line2_chars), line3],
                     previous_char, movement_info}
                end

              _ ->
                line2_chars = chars_to_the_left ++ [?<, ?+] ++ chars_to_the_right
                {[line1, List.to_string(line2_chars), line3], char_to_the_left, movement_info}
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
                {[line1, List.to_string(line2_chars), List.to_string(line3_chars)], previous_char,
                 movement_info}
            end
        end
    end
  end

  def move_right(
        absolute_line_index,
        guard_index,
        previously,
        movement_info,
        line1,
        line2,
        line3,
        line1_chars,
        line2_chars,
        line3_chars
      ) do
    char_to_the_right = line2_chars |> Enum.at(guard_index + 1)

    case char_to_the_right do
      # move down, place X
      c when c in [?#, ?O] ->
        {line2_chars_to_the_left, [_guard | line2_chars_to_the_right]} =
          Enum.split(line2_chars, guard_index)

        {line3_chars_to_the_left, [previous_char | line3_chars_to_the_right]} =
          Enum.split(line3_chars, guard_index)

        filler = ?+

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
                # turn around
                directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

                case Enum.member?(directions, "left") do
                  true ->
                    :cycle_detected

                  false ->
                    movement_info =
                      Map.put(movement_info, {absolute_line_index, guard_index}, [
                        "left" | directions
                      ])

                    line2_chars_to_the_left =
                      line2_chars_to_the_left |> Enum.reverse() |> tl() |> Enum.reverse()

                    line2_chars = line2_chars_to_the_left ++ [?<, ?+] ++ line2_chars_to_the_right
                    {[line1, List.to_string(line2_chars), line3], ?+, movement_info}
                end

              _ ->
                line2_chars = line2_chars_to_the_left ++ [filler] ++ line2_chars_to_the_right
                line3_chars = line3_chars_to_the_left ++ [?v] ++ line3_chars_to_the_right

                {[line1, List.to_string(line2_chars), List.to_string(line3_chars)], previous_char,
                 movement_info}
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
  end

  def move_left(
        absolute_line_index,
        guard_index,
        previously,
        movement_info,
        line1,
        line2,
        line3,
        line1_chars,
        line2_chars,
        line3_chars
      ) do
    i = guard_index - 1

    char_to_the_left =
      case i do
        i when i >= 0 -> line2_chars |> Enum.at(guard_index - 1)
        _ -> nil
      end

    case char_to_the_left do
      # move up
      c when c in [?#, ?O] ->
        {line1_chars_to_the_left, [char_above | line1_chars_to_the_right]} =
          Enum.split(line1_chars, guard_index)

        {line2_chars_to_the_left, [guard | line2_chars_to_the_right]} =
          Enum.split(line2_chars, guard_index)

        directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

        case Enum.member?(directions, "up") do
          true ->
            :cycle_detected

          false ->
            movement_info =
              Map.put(movement_info, {absolute_line_index, guard_index}, ["up" | directions])

            case char_above do
              # above is also a wall. so turn around
              x when x in [?#, ?O] ->
                directions = Map.get(movement_info, {absolute_line_index, guard_index}, [])

                case Enum.member?(directions, "right") do
                  true ->
                    :cycle_detected

                  false ->
                    movement_info =
                      Map.put(movement_info, {absolute_line_index, guard_index}, [
                        "right" | directions
                      ])

                    [_ | line2_chars_to_the_right] = line2_chars_to_the_right
                    line2_chars = line2_chars_to_the_left ++ [?+, ?>] ++ line2_chars_to_the_right

                    {[line1, List.to_string(line2_chars), line3], previously, movement_info}
                end

              # new chunk
              _ ->
                line2_chars = line2_chars_to_the_left ++ [?+] ++ line2_chars_to_the_right
                line1_chars = line1_chars_to_the_left ++ [?^] ++ line1_chars_to_the_right

                {[List.to_string(line1_chars), List.to_string(line2_chars), line3], char_above,
                 movement_info}
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

            {[line1, List.to_string(line2_chars), line3], previous_char, movement_info}
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
          c when c in [?+, ?-, ?|] ->
            {[counter] ++ indexes, counter}

          _ ->
            {indexes, counter}
            # _ -> {[counter] ++ indexes, counter}
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

  def check_for_cycle(lines, {x, y, direction} = position, %{} = history) do
    # store direction of index in history
    # IO.inspect("-")
    # IO.inspect({x, y, direction, history})

    previous_directions = Map.get(history, {x, y}, [])
    already_went_this_direction? = Enum.member?(previous_directions, direction)

    case already_went_this_direction? do
      true ->
        # IO.puts("> cycle detected!")
        :cycle_detected

      false ->
        history = Map.put(history, {x, y}, [direction | previous_directions])

        # update the guard's position
        ## check the region around the guard, turn if necessary, then move one space

        case _move_guard(lines, position) do
          :solved ->
            # IO.puts("> solved!")
            :solved

          {x, y, direction} ->
            # :timer.sleep(1000)
            check_for_cycle(lines, {x, y, direction}, history)
        end
    end
  end

  def _move_guard(lines, {x, y, direction} = position) do
    chunk =
      lines
      |> Enum.reduce({0, []}, fn line, {index, chunk} ->
        line1 = y - 1
        line2 = y
        line3 = y + 1

        case index do
          t when t in [line1, line2, line3] -> {index + 1, chunk ++ [line]}
          _ -> {index + 1, chunk}
        end
      end)
      |> elem(1)
      |> Enum.map(&String.to_charlist/1)
      |> Enum.map(fn line_array ->
        line_array
        |> Enum.reduce({0, []}, fn char, {index, chars} ->
          case index do
            g when g in [x - 1, x, x + 1] -> {index + 1, chars ++ [char]}
            _ -> {index + 1, chars}
          end
        end)
        |> elem(1)
      end)

    line_length = String.length(hd(lines))
    max_x = line_length - 1
    amount_lines = length(lines)
    max_y = amount_lines - 1

    case position do
      {0, _, :left} ->
        :solved

      {_, 0, :up} ->
        :solved

      {^max_x, _, :right} ->
        :solved

      {_, ^max_y, :down} ->
        :solved

      _ ->
        case {length(chunk), y} do
          {2, 0} ->
            [
              [one, _two, three],
              [_four, five, _six]
            ] = chunk

            case direction do
              :up ->
                :solved

              :down ->
                case five do
                  b when b in [?#, ?O] -> {x, y, :left}
                  _ -> {x, y + 1, :down}
                end

              :left ->
                case one do
                  b when b in [?#, ?O] -> {x, y, :up}
                  _ -> {x - 1, y, :left}
                end

              :right ->
                case three do
                  b when b in [?#, ?O] -> {x, y, :down}
                  _ -> {x + 1, y, :right}
                end
            end

          {2, line_length} ->
            [
              [_one, two, _three],
              [four, _five, six]
            ] = chunk

            case direction do
              :up ->
                case two do
                  two when two in [?#, ?O] -> {x, y, :right}
                  _ -> {x, y - 1, :up}
                end

              :down ->
                :solved

              :left ->
                case four do
                  b when b in [?#, ?O] -> {x, y, :up}
                  _ -> {x - 1, y, :left}
                end

              :right ->
                case six do
                  b when b in [?#, ?O] -> {x, y, :down}
                  _ -> {x + 1, y, :right}
                end
            end

          {3, _} ->
            [
              [_one, two, _three],
              [four, _five, six],
              [_seven, eight, _nine]
            ] = chunk

            case direction do
              :up ->
                case two do
                  two when two in [?#, ?O] -> {x, y, :right}
                  _ -> {x, y - 1, :up}
                end

              :down ->
                case eight do
                  b when b in [?#, ?O] -> {x, y, :left}
                  _ -> {x, y + 1, :down}
                end

              :left ->
                case four do
                  b when b in [?#, ?O] -> {x, y, :up}
                  _ -> {x - 1, y, :left}
                end

              :right ->
                case six do
                  b when b in [?#, ?O] -> {x, y, :down}
                  _ -> {x + 1, y, :right}
                end
            end
        end
    end
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
    # can_be_altered? = String.contains?(line, ["+", "-", "|"])
    can_be_altered? = true

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

results =
  map_variations_with_new_obstacle
  |> Enum.map(fn variant ->
    Task.async(fn ->
      # todo find player position
      #    IO.puts("\n----\n")
      #    IO.puts(variant |> Enum.reduce(fn line, c -> c <> "\n" <> line end))

      start_pos =
        variant
        |> Enum.reduce({:not_found, -1, -1}, fn line, result ->
          case result do
            {:found, _, _} ->
              result

            _ ->
              {_, x, y} = result

              case String.contains?(line, "^") do
                true ->
                  # get x pos
                  [left, _] = String.split(line, "^", parts: 2)
                  {:found, String.length(left), y + 1}

                false ->
                  {:not_found, x, y + 1}
              end
          end
        end)

      case start_pos do
        {:found, x, y} -> Day6.check_for_cycle(variant, {x, y, :up}, %{})
        _ -> :not_found
      end
    end)

    #  Day6.predict_next_position(variant)
  end)
  |> Enum.map(fn task -> Task.await(task, :infinity) end)

count_of_loops =
  results
  |> Enum.filter(fn result -> result == :cycle_detected end)
  |> Enum.count()

count_of_invalid =
  results
  |> Enum.filter(fn result -> result == :solved end)
  |> Enum.count()

IO.inspect("Found loops:")
IO.inspect(count_of_loops)
IO.inspect("Found solved:")
IO.inspect(count_of_invalid)

## todo , try simply move like it should, and keep track of a map with the visited indexes and the directions, instead of drawing everything
