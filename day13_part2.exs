defmodule Day13 do
  def solve(filepath) do
    games = read_games_from_file(filepath)

    games =
      games
      |> Enum.map(fn [button_a_line, button_b_line, prize_target_line] ->
        button_regex = ~r/.+X\+(?<xoffset>\d+), Y\+(?<yoffset>\d+)/
        a_map = Regex.named_captures(button_regex, button_a_line)
        b_map = Regex.named_captures(button_regex, button_b_line)

        prize_regex = ~r/.+X=(?<xtarget>\d+), Y=(?<ytarget>\d+)/
        prize_map = Regex.named_captures(prize_regex, prize_target_line)

        {a_x_offset, _} = Integer.parse(a_map["xoffset"])
        {a_y_offset, _} = Integer.parse(a_map["yoffset"])

        {b_x_offset, _} = Integer.parse(b_map["xoffset"])
        {b_y_offset, _} = Integer.parse(b_map["yoffset"])

        {target_x, _} = Integer.parse(prize_map["xtarget"])
        {target_y, _} = Integer.parse(prize_map["ytarget"])

        {
          {a_x_offset, a_y_offset},
          {b_x_offset, b_y_offset},
          {target_x + 10_000_000_000_000, target_y + 10_000_000_000_000}
        }
      end)

    games
    |> Enum.map(&find_solutions/1)
    |> Enum.reduce(&Kernel.+/2)
  end

  defp read_games_from_file(filepath) do
    File.stream!(filepath, :line)
    |> Enum.chunk_every(4)
    |> Enum.map(fn chunk ->
      chunk
      |> Enum.map(&String.trim/1)
      |> Enum.filter(fn line -> line != "" end)
    end)
  end

  defp find_solutions({{ax, ay}, {bx, by}, {tx, ty}} = game) do
    # try a math-y approach, by getting the point where
    #  tx = ax * a + bx * b
    #  ty = ay * a + by * b

    # taken from here: https://topaz.github.io/paste/#XQAAAQBUAwAAAAAAAAA7mkrvHeIvDZUizuaPfPeAcKMhOMDGDR2kTYsySUVnJ3f/diTN6mOIjFS5OADZU7qvDn40ZbF49Mwd4XqZqU6Oy8FTGoKVXo5KgJnE/tbCX28KVqYKkh1tgtlJNjicjLWRjqwOrdUURUSpaSZc8Z+G3iZMBQKQjInV7lPyHBed0kkIRjpZjXWKVdrKHFtFDFUoDWUdCPmIzX0cxpZuUsIO7yIFgrEy7XopBx8N5SkJlCgdawnxLegeai4Qd9X/5VMDJbTyAEshDJEFVWo/DKpqxzOFdPPQ5pRJMfoyIsbkjkLe5paEqXZa2CT6ScPJao5Nwzmz6+cN1r1LYC0/2xvTRdGVC40kpX50edkhXWfnqpJzkiCUqySFqws4B0Hr33j6AwnC/Gml0ymlTWJKo0ZlejQquaoT4y/75J3IhnHEXkolodKnnkDg/vQiFEpu3bFUKzY319RmZM0qRe9nhtH7P/wr5oY=
    b = floor((tx * ay - ty * ax) / (ay * bx - by * ax))
    a = floor((tx * by - ty * bx) / (by * ax - bx * ay))

    case ax * a + bx * b == tx and ay * a + by * b == ty do
      true -> 3 * a + b
      false -> 0
    end
  end
end

IO.inspect(Day13.solve(hd(System.argv())))
