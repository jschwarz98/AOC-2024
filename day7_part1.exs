defmodule Day7 do
  def can_create({result, numbers}) do
    # todo check if numbers can be added / multiplied to get result
    [n | numbers] = numbers
    {combobulate(result, n, numbers), result}
  end

  defp combobulate(target, current, []), do: target == current

  defp combobulate(target, current, numbers) do
    [n | numbers] = numbers
    combobulate(target, current + n, numbers) or combobulate(target, current * n, numbers)
  end
end

total_amount =
  File.stream!("day7.data", :line)
  |> Enum.map(&String.trim/1)
  |> Enum.map(fn line ->
    [result, numbers] = String.split(line, ":", parts: 2, trim: true)

    number_list = String.split(numbers, " ", trim: true)

    {result, _} = Integer.parse(result)

    number_list =
      number_list
      |> Enum.map(&Integer.parse/1)
      |> Enum.map(fn e -> elem(e, 0) end)

    {result, number_list}
  end)
  |> Enum.map(&Day7.can_create/1)
  |> Enum.filter(fn {can_create, _} -> can_create end)
  |> Enum.map(fn e -> elem(e, 1) end)
  |> Enum.reduce(&Kernel.+/2)

IO.inspect(total_amount)
