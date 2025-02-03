defmodule Day21 do
  def solve(path, depth) do
    dir_pads =
      1..depth
      |> Enum.map(fn _ -> dir_pad() end)

    key_pads = [num_pad()] ++ dir_pads

    complexity =
      File.stream!(path)
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn code ->
        {result, _cache} = encode_key_presses(code, key_pads, %{})
        complexity = calc_complexity(code, result)
        complexity
      end)
      |> Enum.reduce(0, &Kernel.+/2)

    IO.inspect({"total complexity: ", complexity})
  end

  defp dir_pad do
    %{
      :avoid => {0, 0},
      ?^ => {1, 0},
      ?A => {2, 0},
      ?< => {0, 1},
      ?v => {1, 1},
      ?> => {2, 1},
      :position => {2, 0}
    }
  end

  defp num_pad do
    %{
      ?7 => {0, 0},
      ?8 => {1, 0},
      ?9 => {2, 0},
      ?4 => {0, 1},
      ?5 => {1, 1},
      ?6 => {2, 1},
      ?1 => {0, 2},
      ?2 => {1, 2},
      ?3 => {2, 2},
      :avoid => {0, 3},
      ?0 => {1, 3},
      ?A => {2, 3},
      :position => {2, 3}
    }
  end

  def encode_key_presses(code, [], cache), do: {String.length(code), cache}

  def encode_key_presses(code, key_pads, cache) do
    {res, _, cache} =
      code
      |> String.to_charlist()
      |> Enum.reduce({0, ?A, cache}, fn key, {result, previous, updated_cache} ->
        {new_result, updated_cache} = encode_key_press(key, key_pads, previous, updated_cache)
        {result + new_result, key, updated_cache}
      end)

    {res, cache}
  end

  defp encode_key_press(key, [key_pad | key_pads], prev, cache) do
    cache_key = {prev, key, length(key_pads)}

    case cache[cache_key] do
      nil ->
        avoid = key_pad[:avoid]
        {x, y} = key_pad[prev]
        {tx, ty} = key_pad[key]
        y_diff = ty - y
        x_diff = tx - x

        y_char =
          case y_diff do
            y_diff when y_diff < 0 -> "^"
            _ -> "v"
          end

        y_movement = String.duplicate(y_char, abs(y_diff))

        x_char =
          case x_diff do
            x_diff when x_diff < 0 -> "<"
            _ -> ">"
          end

        x_movement = String.duplicate(x_char, abs(x_diff))

        # check both ways to move (if legal) and pick the shorter result
        {result, updated_cache} =
          [
            {{x, ty}, y_movement <> x_movement <> "A"},
            {{tx, y}, x_movement <> y_movement <> "A"}
          ]
          |> Enum.filter(fn {check_for_avoid, _} -> check_for_avoid != avoid end)
          |> Enum.map(fn {_, new_code} -> encode_key_presses(new_code, key_pads, cache) end)
          |> Enum.min_by(fn {res, _updated_cache} -> res end)

        {result, updated_cache |> Map.put(cache_key, result)}

      something ->
        {something, cache}
    end
  end

  def calc_complexity(code, result) do
    {factor, _} = Integer.parse(code)

    IO.inspect({code, "=>", result, "*", factor})
    result * factor
  end
end

Day21.solve("day21.data", 25)
