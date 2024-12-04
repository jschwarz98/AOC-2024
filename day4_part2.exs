defmodule Day4 do
  def count_xmas([r1, r2, r3]) do
    p1 = r1 |> String.to_charlist()
    p2 = r2 |> String.to_charlist()
    p3 = r3 |> String.to_charlist()

    left_to_right =
      Enum.zip(p1, p2)
      |> Enum.zip(p3)
      |> Enum.flat_map(fn z ->
        {{v1, v2}, v3} = z
        # v1 <> v2 <> v3
        [v1, v2, v3]
      end)
      |> Enum.chunk_every(9, 3, :discard)
      |> Enum.filter(fn chunk ->
        # string of nine letters
        # 1 4 7     M _ M
        # 2 5 8  => _ A _
        # 3 6 9     S _ S
        [one, _, three, _, five, _, seven, _, nine] = chunk

        case five == ?A and
               ((one == ?M and nine == ?S) or
                  (one == ?S and nine == ?M)) and
               ((three == ?M and seven == ?S) or
                  (three == ?S and seven == ?M)) do
          true -> true
          false -> false
        end
      end)
      |> Enum.count()
  end
end

all_lines =
  File.stream!("./day4.data", :line)
  |> Enum.map(&String.trim/1)

count_lines = Enum.count(all_lines)
IO.inspect({"in total we have", count_lines, "lines"})

chunks =
  all_lines
  |> Enum.map(&String.trim_trailing/1)
  |> Enum.chunk_every(3, 1, :discard)

xmas_result =
  chunks
  |> Enum.map(&Day4.count_xmas/1)
  |> Enum.reduce(0, &Kernel.+/2)

IO.inspect("===")
IO.inspect(xmas_result)
