defmodule Day4 do
  def count_diagonal_ltr([r1, r2, r3, r4]) do
    [_, _, _ | p1] = r1 |> String.to_charlist()
    [_, _ | p2] = r2 |> String.to_charlist()
    [_ | p3] = r3 |> String.to_charlist()
    p4 = r4 |> String.to_charlist()

    left_to_right =
      Enum.zip(p1, p2)
      |> Enum.zip(p3)
      |> Enum.zip(p4)
      |> Enum.map(fn z ->
        {{{v1, v2}, v3}, v4} = z
        # v1 <> v2 <> v3 <> v4
        String.Chars.List.to_string([v1, v2, v3, v4])
      end)

    left_to_right
    |> Enum.reduce(0, fn s, acc ->
      case s == "XMAS" or s == "SAMX" do
        true -> acc + 1
        false -> acc
      end
    end)
  end

  def count_diagonal_rtl([r1, r2, r3, r4]) do
    count_diagonal_ltr([
      r1 |> String.reverse(),
      r2 |> String.reverse(),
      r3 |> String.reverse(),
      r4 |> String.reverse()
    ])
  end

  def count_vertical([r1, r2, r3, r4]) do
    Enum.zip(
      String.to_charlist(r1),
      String.to_charlist(r2)
    )
    |> Enum.zip(String.to_charlist(r3))
    |> Enum.zip(String.to_charlist(r4))
    |> Enum.map(fn z ->
      {{{v1, v2}, v3}, v4} = z
      # v1 <> v2 <> v3 <> v4

      String.Chars.List.to_string([v1, v2, v3, v4])
    end)
    |> Enum.reduce(0, fn s, acc ->
      case s == "XMAS" or s == "SAMX" do
        true -> acc + 1
        false -> acc
      end
    end)
  end

  def count_horizontal(line) when is_binary(line) do
    line
    |> String.to_charlist()
    |> Enum.chunk_every(4, 1, :discard)
    |> Enum.reduce(0, fn chars, acc ->
      segment = String.Chars.List.to_string(chars)

      case segment == "XMAS" or segment == "SAMX" do
        true -> acc + 1
        false -> acc
      end
    end)
  end

  def count_horizontal(line) when is_list(line) do
    line
    |> Enum.reduce(0, fn l, acc -> count_horizontal(l) + acc end)
  end
end

all_lines =
  File.stream!("./day4.data", :line)
  |> Enum.map(&String.trim/1)

count_lines = Enum.count(all_lines)
IO.inspect({"in total we have", count_lines, "lines"})

horizontal_result =
  all_lines
  |> Enum.map(&Day4.count_horizontal/1)
  |> Enum.reduce(0, &Kernel.+/2)

chunks =
  all_lines
  |> Enum.map(&String.trim_trailing/1)
  |> Enum.chunk_every(4, 1, :discard)

vertical_result =
  chunks
  |> Enum.map(&Day4.count_vertical/1)
  |> Enum.reduce(0, &Kernel.+/2)

diagonal_ltr_result =
  chunks
  |> Enum.map(&Day4.count_diagonal_ltr/1)
  |> Enum.reduce(0, &Kernel.+/2)

diagonal_rtl_result =
  chunks
  |> Enum.map(&Day4.count_diagonal_rtl/1)
  |> Enum.reduce(0, &Kernel.+/2)

IO.inspect({"horizontal_result", horizontal_result})
IO.inspect({"vertical_result", vertical_result})
IO.inspect({"diagonal_ltr_result", diagonal_ltr_result})
IO.inspect({"diagonal_rtl_result", diagonal_rtl_result})

IO.inspect("===")
IO.inspect(horizontal_result + vertical_result + diagonal_ltr_result + diagonal_rtl_result)
