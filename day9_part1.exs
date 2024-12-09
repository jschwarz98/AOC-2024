defmodule Day9 do
  @dot "."
  def translate_into_block_line(str) do
    {_, _, result} =
      str
      |> String.to_charlist()
      |> Enum.reduce({:file, 0, []}, fn char, {mode, file_count, result} ->
        {amount, _} = Integer.parse(List.to_string([char]))

        case mode do
          :space ->
            result =
              case amount do
                0 ->
                  result

                _ ->
                  1..amount
                  |> Enum.reduce(result, fn _, result ->
                    [@dot | result]
                  end)
              end

            {:file, file_count, result}

          :file ->
            result =
              case amount do
                0 ->
                  result

                _ ->
                  1..amount
                  |> Enum.reduce(result, fn _, acc ->
                    num = Integer.to_string(file_count)
                    [num | acc]
                  end)
              end

            {:space, file_count + 1, result}
        end
      end)

    IO.inspect(result)
    result |> Enum.reverse()
  end

  def defragment_system(blocks) do
    first_dot_at = Enum.find_index(blocks, fn item -> item === "." end)

    {before_dot, [dot | after_dot]} = Enum.split(blocks, first_dot_at)

    after_dot_reversed =
      after_dot
      |> Enum.reverse()

    first_digit_at = Enum.find_index(after_dot_reversed, fn item -> item !== "." end)

    case first_digit_at do
      nil ->
        blocks

      _ ->
        {before_digit, [digit | after_digit]} = Enum.split(after_dot_reversed, first_digit_at)

        new_after_dot = before_digit ++ [dot] ++ after_digit

        ending = Enum.reverse(new_after_dot)

        str = before_dot ++ [digit] ++ ending

        defragment_system(str)
    end
  end
end

[input] =
  File.stream!("day9.data", :line)
  |> Enum.map(&String.trim/1)

IO.puts("blocked:")
b = Day9.translate_into_block_line(input)

IO.inspect(b)
IO.puts("defragged:")
defrag = Day9.defragment_system(b)
IO.inspect(defrag)

checksum =
  defrag
  |> Enum.reduce({0, 0}, fn int_string, {index, value} ->
    case int_string do
      "." ->
        {index + 1, value}

      _ ->
        {v, _} = Integer.parse(int_string)
        v = v * index
        {index + 1, value + v}
    end
  end)
  |> elem(1)

IO.puts("checksum:")
IO.inspect(checksum)
