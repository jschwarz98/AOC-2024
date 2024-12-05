defmodule Day5 do
  def valid?(numbers, rules) when is_map(rules) and is_list(numbers) do
    number_left_right_map = split_numbers_into_left_right_map(numbers)
    # IO.inspect({"looking at numbers", numbers}, charlists: :as_lists)

    all_valid? =
      numbers
      |> Enum.map(fn n ->
        # IO.inspect({"number:", n})
        {numbers_to_the_left, numbers_to_the_right} = Map.get(number_left_right_map, n)
        {allowed_on_the_left, allowed_on_the_right} = Map.get(rules, n)

        valid_left? = check(numbers_to_the_left, allowed_on_the_right)
        valid_right? = check(numbers_to_the_right, allowed_on_the_left)

        valid_left? and valid_right?
      end)
      |> Enum.all?(& &1)

    {numbers, all_valid?}
  end

  defp check(other_numbers, not_allowed_numbers) do
    not_allowed_number? =
      other_numbers
      |> Enum.any?(&Enum.member?(not_allowed_numbers, &1))

    !not_allowed_number?
  end

  defp split_numbers_into_left_right_map(numbers) do
    length = length(numbers)

    0..(length - 1)
    |> Enum.reduce(%{}, fn index, acc ->
      {left, right} = Enum.split(numbers, index)
      # current element
      [number | right] = right
      Map.put(acc, number, {left, right})
    end)
  end

  def turn_invalid_into_valid({numbers, _}, rules), do: turn_invalid_into_valid(numbers, rules)

  def turn_invalid_into_valid(numbers, rules) when is_list(numbers) do
    case Day5.valid?(numbers, rules) do
      {_, true} ->
        numbers

      {_, false} ->
        # falls nicht valid
        # schauen was für zahlen in welcher reihenfolge...
        number_left_right_map = split_numbers_into_left_right_map(numbers)

        # reduce the numbers, until you find an invalid one
        {status, n_index, p_index, side} =
          numbers
          |> Enum.reduce({:ok, -1, -1, :valid_left}, fn n, acc ->
            case acc do
              {:invalid, _, _, _} ->
                acc

              _ ->
                {numbers_to_the_left, numbers_to_the_right} = Map.get(number_left_right_map, n)
                {allowed_on_the_left, allowed_on_the_right} = Map.get(rules, n)

                {invalid_left?, problematic_number} =
                  check_invalid_number(numbers_to_the_left, allowed_on_the_right)

                result =
                  case invalid_left? do
                    true ->
                      n_index = Enum.find_index(numbers, fn t -> t == n end)

                      problem_index =
                        Enum.find_index(numbers, fn t -> t == problematic_number end)

                      {:invalid, n_index, problem_index, :invalid_left}

                    false ->
                      {:ok, -1, -1, :ok_left}
                  end

                case result do
                  {:invalid, _, _, _} ->
                    result

                  {:ok, _, _, _} ->
                    {invalid_right?, problematic_number} =
                      check_invalid_number(numbers_to_the_right, allowed_on_the_left)

                    case invalid_right? do
                      true ->
                        n_index = Enum.find_index(numbers, fn t -> t == n end)

                        problem_index =
                          Enum.find_index(numbers, fn t -> t == problematic_number end)

                        {:invalid, n_index, problem_index, :invalid_right}

                      false ->
                        {:ok, -1, -1, :ok_right}
                    end
                end
            end
          end)

        case status do
          :ok ->
            numbers

          :invalid ->
            ## todo swap numbers
            ## try again
            new_numbers =
              case side do
                :invalid_left ->
                  {left, [number | right]} = Enum.split(numbers, n_index)
                  {left_left, [problem | left_right]} = Enum.split(left, p_index)
                  left_left ++ [number] ++ left_right ++ [problem] ++ right

                :invalid_right ->
                  {left, [number | right]} = Enum.split(numbers, n_index)
                  {right_left, [problem | right_right]} = Enum.split(right, p_index - n_index - 1)
                  left ++ [problem] ++ right_left ++ [number] ++ right_right
              end

            turn_invalid_into_valid(new_numbers, rules)
        end
    end
  end

  defp check_invalid_number(other_numbers, not_allowed_numbers) do
    not_allowed_number? =
      other_numbers
      |> Enum.find(fn num -> Enum.member?(not_allowed_numbers, num) end)

    case not_allowed_number? != nil do
      true -> {true, not_allowed_number?}
      false -> {false, 0}
    end
  end

  def permutations([]), do: []
  def permutations([e]), do: [[e]]

  def permutations(list) do
    1..length(list)
    |> Enum.flat_map(fn index ->
      {left, [number | right]} = Enum.split(list, index - 1)
      permutations(left ++ right) |> Enum.map(fn l -> [number | l] end)
    end)
  end
end

{rules, inputs, _} =
  File.stream!("./day5.data", :line)
  |> Enum.map(&String.trim/1)
  |> Enum.reduce({[], [], true}, fn o, acc ->
    {rules, inputs, reading_rules} = acc

    case o do
      "" ->
        {rules, inputs, false}

      _ ->
        case reading_rules do
          true -> {[o | rules], inputs, reading_rules}
          false -> {rules, [o | inputs], reading_rules}
        end
    end
  end)

rules =
  rules
  |> Enum.reduce(%{}, fn rule, acc ->
    [l, r] = rule |> String.split("|")
    {l, _} = l |> Integer.parse()
    {r, _} = r |> Integer.parse()

    map = acc
    has_left_value? = Map.has_key?(map, l)

    map =
      case has_left_value? do
        true ->
          {allowed_before, allowed_after} = Map.get(map, l)
          Map.put(map, l, {allowed_before, [r | allowed_after]})

        false ->
          Map.put(map, l, {[], [r]})
      end

    has_right_value? = Map.has_key?(map, r)

    map =
      case has_right_value? do
        true ->
          {allowed_before, allowed_after} = Map.get(map, r)
          Map.put(map, r, {[l | allowed_before], allowed_after})

        false ->
          Map.put(map, r, {[l], []})
      end

    map
  end)

inputs =
  inputs
  |> Enum.map(&String.split(&1, ","))
  |> Enum.map(fn parts ->
    parts
    |> Enum.map(&Integer.parse/1)
    |> Enum.map(&elem(&1, 0))
  end)

# IO.inspect(rules, charlists: :as_lists)
# IO.inspect(inputs, charlists: :as_lists)

invalid_inputs =
  inputs
  |> Enum.map(&Day5.valid?(&1, rules))
  |> Enum.filter(fn e -> elem(e, 1) == false end)

IO.inspect({"invalid inputs? #", invalid_inputs |> Enum.count()})
## TODO optimize this step, i check the validity twice here..
corrected_inputs =
  invalid_inputs
  |> Enum.map(&Day5.turn_invalid_into_valid(&1, rules))

IO.inspect("===")

sum_of_middle_values =
  corrected_inputs
  |> Enum.map(fn numbers ->
    len = length(numbers)
    i = Integer.floor_div(len, 2)
    Enum.at(numbers, i)
  end)
  |> Enum.reduce(0, &Kernel.+/2)

IO.inspect(sum_of_middle_values)
