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
          {target_x, target_y}
        }
      end)

    games
    |> Enum.map(&find_solutions/1)
    |> Enum.map(&elem(&1, 0))
    |> Enum.map(&MapSet.to_list/1)
    |> Enum.filter(fn solutions -> not Enum.empty?(solutions) end)
    |> Enum.map(fn solutions ->

      if Enum.empty?(solutions) do
        :no_result
      else
        solutions
        |> Enum.map(fn {a_presses, b_presses} -> a_presses * 3 + b_presses * 1 end)
        |> Enum.min()
      end

    end)
    |> Enum.filter(fn min -> min != :no_result end)
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

  defp find_solutions(
         {{a_x_offset, a_y_offset}, {b_x_offset, b_y_offset}, {target_x, target_y}} = game,
         a_button_presses \\ 0,
         b_button_presses \\ 0,
         current_x \\ 0,
         current_y \\ 0,
         solutions \\ MapSet.new(),
         already_checked \\ %{}
       ) do

    case {current_x, current_y} do
      {current_x, current_y} when current_x > target_x or current_y > target_y ->
        {solutions, already_checked}

      {current_x, current_y} when current_x == target_x and current_y == target_y ->
        solutions = MapSet.put(solutions, {a_button_presses, b_button_presses})
        {solutions, Map.put(already_checked, {a_button_presses, b_button_presses}, solutions)}

      _ ->
        case Map.get(already_checked, {a_button_presses, b_button_presses}) do
          nil ->
            {solutions, already_checked} =
              find_solutions(
                game,
                a_button_presses + 1,
                b_button_presses,
                current_x + a_x_offset,
                current_y + a_y_offset,
                solutions,
                already_checked
              )

            {solutions, already_checked} =
              find_solutions(
                game,
                a_button_presses,
                b_button_presses + 1,
                current_x + b_x_offset,
                current_y + b_y_offset,
                solutions,
              already_checked
              )

            already_checked  = Map.put(already_checked, {a_button_presses, b_button_presses}, solutions)

            {solutions, already_checked}

          set ->
            {set, already_checked}
        end
    end
  end
end

IO.inspect(Day13.solve(hd(System.argv())))
