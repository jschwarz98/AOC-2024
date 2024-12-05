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
    # IO.inspect({"other", other_numbers, "not_allowed", not_allowed_numbers}, charlists: :as_lists)

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

valid_inputs =
  inputs
  |> Enum.map(&Day5.valid?(&1, rules))
  |> Enum.filter(&elem(&1, 1))

count =
  valid_inputs
  |> Enum.count()

IO.inspect("===")
IO.inspect(count)

sum_of_middle_values =
  valid_inputs
  |> Enum.map(fn {numbers, _} ->
    len = length(numbers)
    i = Integer.floor_div(len, 2)
    Enum.at(numbers, i)
  end)
  |> Enum.reduce(0, &Kernel.+/2)

IO.inspect(sum_of_middle_values)
