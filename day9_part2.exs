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
                    num = file_count
                    [num | acc]
                  end)
              end

            {:space, file_count + 1, result}
        end
      end)

    result |> Enum.reverse()
  end

  def defragment_system(blocks) do
    first_id = Enum.reverse(blocks) |> Enum.find(fn item -> item !== "." end)
    block_length = Enum.count(blocks)
    defrag(blocks, first_id, block_length)
  end

  defp defrag(blocks, 0, _), do: blocks

  defp defrag(blocks, id, block_length) do
    i1 = Enum.find_index(blocks, fn item -> item === id end)
    i2 = Enum.reverse(blocks) |> Enum.find_index(fn item -> item === id end)
    chunk_size = block_length - i1 - i2


    {has_space?, index} = blocks
      |> Enum.chunk_every(chunk_size, 1, :discard)
      |> Enum.reduce({:no_free_space, 0}, fn chunk, {status, index} = acc ->
        case status do
          :found_space -> acc
          :no_free_space ->
            case Enum.all?(chunk, fn item -> item === "." end) do
              true -> {:found_space, index}
              false -> {:no_free_space, index + 1}
            end
        end
      end)

      blocks = case {has_space?, index < i1} do
        {:no_free_space, _} ->
          blocks
          {:found_space, false} -> blocks

        {:found_space, true} -> # todo
          {left_of_free_space, right_side } = Enum.split(blocks, index)
          {removed_elements, remaining_after_free_space} = Enum.split(right_side, chunk_size)

          {middle_part, file_section_and_after} = Enum.split(remaining_after_free_space, i1 - index - chunk_size)
          {file_section, rest_of_blocks} = Enum.split(file_section_and_after, chunk_size)

          left_of_free_space ++ file_section ++ middle_part ++ removed_elements ++ rest_of_blocks
      end

      defrag(blocks, id - 1, block_length)
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
        v = int_string * index
        {index + 1, value + v}
    end
  end)
  |> elem(1)

IO.puts("checksum:")
IO.inspect(checksum)
