{left_numbers, right_numbers} =
  File.stream!("./day1.data", :line)
  |> Enum.map(fn line -> String.split(line, "   ", trim: true) end)
  |> Enum.reduce({[], []}, fn numbers, acc ->
    case (is_binary(numbers) and numbers == "") or (is_list(numbers) and Enum.empty?(numbers)) do
      true ->
        acc

      false ->
        {left_numbers, right_numbers} = acc

        [left, right] = numbers
        right = String.slice(right, 0, String.length(right) - 1)

        left_numbers = [left | left_numbers]
        right_numbers = [right | right_numbers]

        {left_numbers, right_numbers}
    end
  end)

left_numbers =
  left_numbers
  |> Enum.map(fn n ->
    {int, _} = Integer.parse(n)
    int
  end)
  |> Enum.sort()

right_numbers =
  right_numbers
  |> Enum.map(fn n ->
    {int, _} = Integer.parse(n)
    int
  end)
  |> Enum.sort()

dif =
  Enum.zip(left_numbers, right_numbers)
  |> Enum.map(fn zip ->
    {n, m} = zip
    abs(n - m)
  end)
  |> Enum.reduce(0, fn value, acc -> acc + value end)

IO.inspect("The results are in:")
IO.inspect(dif)
