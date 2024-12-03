defmodule Day3 do
  def parseMuls(line) do
    Regex.scan(~r/mul\([0-9]{1,3},[0-9]{1,3}\)/, line)
    |> Enum.flat_map(fn i -> i end)
    |> Enum.map(fn i ->
      i
      |> String.slice(4..-2//1)
      |> String.split(",")
      |> Enum.map(fn n ->
        {int, _} = Integer.parse(n)
        int
      end)
      |> Enum.reduce(fn a, b -> a * b end)
    end)
    |> Enum.reduce(&Kernel.+/2)
  end
end

result =
  File.stream!("./day3.data", :line)
  |> Enum.map(&Day3.parseMuls/1)
  |> Enum.reduce(0, &Kernel.+/2)

IO.inspect("The result is in:")
IO.inspect(result)
