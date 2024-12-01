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

# %{ number => count }
freqs =
  right_numbers
  |> Enum.map(fn n ->
    {int, _} = Integer.parse(n)
    int
  end)
  |> Enum.frequencies()

dif_value =
  left_numbers
  |> Enum.map(fn n ->
    {int, _} = Integer.parse(n)

    case Map.has_key?(freqs, int) do
      true ->
        int * freqs[int]

      false ->
        0
    end
  end)
  |> Enum.reduce(0, fn a, b -> a + b end)

IO.inspect("The results are in:")
IO.inspect(dif_value)
