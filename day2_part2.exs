defmodule Day2 do
  def line_to_int_list(number_line) do
    String.split(number_line, " ", trim: true)
    |> Enum.map(fn number ->
      {int, _} = Integer.parse(number)
      int
    end)
  end

  def permutations(numbers) do
    # turn this list into a list of lists, each with one number missing
    total_amount = Enum.count(numbers)

    0..(total_amount - 1)
    |> Enum.map(fn exclude_index ->
      Enum.slice(numbers, 0, exclude_index) ++
        Enum.slice(numbers, exclude_index + 1, total_amount - exclude_index)
    end)
  end

  def check_asc(numbers) do
    # do this, but with one number missing, try every option of missing number

    numbers
    |> permutations()
    |> Enum.reduce(false, fn perm, asc? ->
      case asc? do
        true ->
          true

        false ->
          [num | rest] = perm
          ascends?(num, rest)
      end
    end)
  end

  def ascends?(_, []), do: true

  def ascends?(number, list) do
    [next | rest] = list

    case number < next and next - number <= 3 do
      false -> false
      true -> ascends?(next, rest)
    end
  end

  def check_desc(numbers) do
    numbers
    |> permutations()
    |> Enum.reduce(false, fn perm, desc? ->
      case desc? do
        true ->
          true

        false ->
          [num | rest] = perm
          descends?(num, rest)
      end
    end)
  end

  def descends?(_, []), do: true

  def descends?(number, list) do
    [next | rest] = list

    case number > next and number - next <= 3 do
      false -> false
      true -> descends?(next, rest)
    end
  end
end

result =
  File.stream!("./day2.data", :line)
  |> Enum.map(&Day2.line_to_int_list(&1))
  |> Enum.map(fn numbers ->
    case numbers do
      [_, _ | _] -> Day2.check_asc(numbers) or Day2.check_desc(numbers)
      _ -> false
    end
  end)
  |> Enum.filter(fn r -> r end)
  |> Enum.count()

IO.inspect(result)
