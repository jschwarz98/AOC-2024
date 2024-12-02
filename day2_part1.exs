defmodule Day2 do
  def line_to_int_list(number_line) do
    String.split(number_line, " ", trim: true)
    |> Enum.map(fn number ->
      {int, _} = Integer.parse(number)
      int
    end)
  end

  def check_asc(numbers) do
    [num | rest] = numbers
    ascends?(num, rest)
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
    [first | rest] = numbers
    descends?(first, rest)
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
      [_] -> true
      [n, m] -> (n > m and n - m <= 3) or (m > n and m - n <= 3)
      [n, m | _] when n < m and m - n <= 3 -> Day2.check_asc(numbers)
      [n, m | _] when n > m and n - m <= 3 -> Day2.check_desc(numbers)
      _ -> false
    end
  end)
  |> Enum.filter(fn r -> r end)
  |> Enum.count()

IO.inspect(result)
