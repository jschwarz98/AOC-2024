defmodule Day11 do
  require Integer

  def count_stones_after_blinks(stones, total_blinks) do
    cache = %{}

    {result, _updated_cache} =
      Enum.reduce(stones, {0, cache}, fn stone, {count, cache} ->
        {n, new_cache} = count_stones(stone, total_blinks, cache)
        {count + n, new_cache}
      end)

    result
  end

  defp count_stones(_stone, 0, cache), do: {1, cache}

  defp count_stones(stone, blinks_left, cache) do
    key = {stone, blinks_left}

    case Map.get(cache, key) do
      nil ->
        new_stones = transform_stone(stone)

        {count, updated_cache} =
          Enum.reduce(new_stones, {0, cache}, fn new_stone, {count, current_cache} ->
            {n, new_cache} = count_stones(new_stone, blinks_left - 1, current_cache)

            {count + n, new_cache}
          end)

        {count, Map.put(updated_cache, key, count)}

      count ->
        {count, cache}
    end
  end

  defp transform_stone(0), do: [1]

  defp transform_stone(stone) do
    stone_as_string = Integer.to_string(stone)
    num_digits = String.length(stone_as_string)

    if Integer.is_even(num_digits) do
      {l, r} = String.split_at(stone_as_string, div(num_digits, 2))
      {l, _} = Integer.parse(l)
      {r, _} = Integer.parse(r)
      [l, r]
    else
      [stone * 2024]
    end
  end
end

# Load the input
initial_stones =
  File.stream!("day11.data", :line)
  |> Enum.map(&String.trim/1)
  |> List.first()
  |> String.split(" ")
  |> Enum.map(fn num ->
    {i, _} = Integer.parse(num)
    i
  end)

# Compute the result for 75 blinks
IO.inspect(Day11.count_stones_after_blinks(initial_stones, 75))
