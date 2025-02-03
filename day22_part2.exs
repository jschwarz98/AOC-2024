defmodule Day22 do
  def step1(secret_number) when is_integer(secret_number) do
    t1 = secret_number * 64
    t2 = Bitwise.bxor(secret_number, t1)
    rem(t2, 16_777_216)
  end

  def step2(secret_number) when is_integer(secret_number) do
    t1 = floor(secret_number / 32)
    t2 = Bitwise.bxor(t1, secret_number)
    rem(t2, 16_777_216)
  end

  def step3(secret_number) when is_integer(secret_number) do
    t1 = secret_number * 2048
    t2 = Bitwise.bxor(t1, secret_number)
    rem(t2, 16_777_216)
  end

  def pipeline(secret_number) do
    secret_number
    |> step1()
    |> step2()
    |> step3()
  end

  def next_x_numbers(secret_number, steps) when is_integer(secret_number) and steps >= 1 do
    first = secret_number

    {_last, numbers} =
      1..steps
      |> Enum.reduce({secret_number, []}, fn _step, {number, numbers} ->
        new_secret_number = pipeline(number)

        {new_secret_number, [new_secret_number | numbers]}
      end)

    [first] ++
      (numbers
       |> Enum.reverse())
  end

  def first_digit(number) do
    number
    |> Integer.to_string()
    |> String.last()
    |> Integer.parse()
    |> elem(0)
  end

  def solve(path) do
    cache = %{}

    diffs =
      File.stream!(path)
      |> Enum.map(&String.trim/1)
      |> Enum.map(&Integer.parse/1)
      |> Enum.map(&elem(&1, 0))
      |> Enum.map(&next_x_numbers(&1, 2000))
      |> Enum.map(fn list ->
        first_numbers = list |> Enum.map(&first_digit/1)
        [first_number | other_first_numbers] = first_numbers

        other_first_numbers
        |> Enum.reduce({first_number, []}, fn other_first_number, {previous, diffs} ->
          diff = other_first_number - previous
          {other_first_number, [{diff, other_first_number} | diffs]}
        end)
        |> elem(1)
        |> Enum.reverse()
      end)

    count_diffs = length(diffs)

    # [ {1, [..]}, {2, [..]}, ...]
    diffs =
      1..count_diffs
      |> Enum.zip(diffs)

    # init empty map for each diff
    cache =
      1..count_diffs
      |> Enum.reduce(cache, fn index, cache -> Map.put(cache, index, %{}) end)

    {all_possible_diffs, cache} =
      diffs
      |> Enum.reduce({MapSet.new(), cache}, fn {index, diffs}, {set, cache} ->
        diffs
        |> Enum.chunk_every(4, 1, :discard)
        |> Enum.reduce({set, cache}, fn [{a, _}, {b, _}, {c, _}, {d, bananas}], {set, cache} ->
          entry = {a, b, c, d}

          updated_cache =
            case cache[index][entry] do
              nil ->
                # only put the first occurence of the diff order
                put_in(cache, [index, entry], bananas)

              _ ->
                # already in cache, but a later value, so we discard it
                cache
            end

          updated_set = MapSet.put(set, entry)

          {updated_set, updated_cache}
        end)
      end)

    all_possible_diffs = MapSet.to_list(all_possible_diffs)

    count_diffs = length(all_possible_diffs)
    chunk_size = floor(count_diffs / 12)

    Enum.chunk_every(all_possible_diffs, chunk_size)
    |> Enum.map(fn chunk_of_target_diffs ->
      Task.async(fn ->
        chunk_of_target_diffs
        |> Enum.map(fn target_diff ->
          diffs
          |> Enum.map(fn {index, _diff_list} ->
            case cache[index][target_diff] do
              nil -> 0
              v -> v
            end
          end)
          |> Enum.reduce(0, &Kernel.+/2)
        end)
        |> Enum.max()
      end)
    end)
    |> Enum.map(fn task -> Task.await(task, :infinity) end)
    |> Enum.max()
  end

  def bananas_for_diff(all_diffs, target_diff) do
    all_diffs
    |> Enum.map(fn diff_list ->
      # [{diff, sell_price}]
      {found?, sell_price} =
        diff_list
        |> Enum.reduce({:search, []}, fn {diff, sell_price}, {search?, previous_diffs} = acc ->
          case search? do
            :found ->
              acc

            :search ->
              diff_window =
                (previous_diffs ++ [diff])
                |> Enum.take(-4)

              case length(diff_window) do
                4 ->
                  [a, b, c, d] = diff_window
                  t = {a, b, c, d}

                  case t do
                    ^target_diff -> {:found, sell_price}
                    _ -> {:search, diff_window}
                  end

                _ ->
                  {:search, diff_window}
              end
          end
        end)

      case found? do
        :search -> 0
        :found -> sell_price
      end
    end)
    |> Enum.reduce(0, &Kernel.+/2)
  end
end

IO.inspect(Day22.solve("day22.data"))
