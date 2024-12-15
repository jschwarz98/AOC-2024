defmodule Day11 do
  require Integer

  def blink_at_stones(stones, counter, stop_at) do
    IO.inspect({"counter", counter, "#stones", Enum.count(stones)})

    case counter do
      ^stop_at ->
        stones

      counter ->
        stones =
          stones
          |> Enum.flat_map(fn stone ->
            stone_as_string = Integer.to_string(stone)
            num_digits = String.length(stone_as_string)

            case Integer.is_even(num_digits) do
              true ->
                {l, r} = String.split_at(stone_as_string, div(num_digits, 2))
                {l, _} = Integer.parse(l)
                {r, _} = Integer.parse(r)
                [l, r]

              false ->
                case stone do
                  0 -> [1]
                  stone -> [stone * 2024]
                end
            end
          end)

        blink_at_stones(stones, counter + 1, stop_at)
    end
  end
end

initial_stones =
  File.stream!("day11.data", :line)
  |> Enum.map(&String.trim/1)
  |> List.first()
  |> String.split(" ")
  |> Enum.map(fn num ->
    {i, _} = Integer.parse(num)
    i
  end)

IO.inspect("initial stones:")
IO.inspect(initial_stones)

IO.inspect(Day11.blink_at_stones(initial_stones, 0, 25) |> Enum.count())
