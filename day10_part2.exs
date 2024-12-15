defmodule Day10 do
  def search(map, max_x, max_y, position) do
    # searches for a way to the number 9 from the starting position (which has to be 0)

    dfs(map, max_x, max_y, position, 0, 0)
  end

  def dfs(_, _, _, _, 9, _) do
    1
  end

  def dfs(map, max_x, max_y, {x, y}, cur, count) do
    # look around x/y for the next higher number (cur + 1), if there is one, dfs on that position, else return counter
    # IO.inspect({"pos", {x, y}, "cur", cur, "counter", set})
    # :timer.sleep(500)

    # IO.inspect({{x, y, cur}, "possible moves from here:"})

    next_moves =
      coordinates_around_point(x, y, max_x, max_y)
      |> Enum.filter(fn coordinate ->
        map[coordinate] === cur + 1
      end)
      |> Enum.map(fn {px, py} ->
        #  IO.inspect({{x, y}, " -> ", {px, py}, "@new", map[{px, py}]})
        {px, py}
      end)

    case next_moves do
      [] ->
        0

      _ ->
        count +
          (next_moves
           |> Enum.map(fn coordinate -> dfs(map, max_x, max_y, coordinate, cur + 1, 0) end)
           |> Enum.reduce(0, &Kernel.+/2))
    end
  end

  def coordinates_around_point(x, y, max_x, max_y) do
    possible_xs =
      case x do
        0 -> [x, x + 1]
        ^max_x -> [x - 1, x]
        _ -> [x - 1, x, x + 1]
      end

    possible_ys =
      case y do
        0 -> [y, y + 1]
        ^max_y -> [y - 1, y]
        _ -> [y - 1, y, y + 1]
      end

    possible_xs
    |> Enum.flat_map(fn possible_x ->
      possible_ys
      |> Enum.map(fn possible_y -> {possible_x, possible_y} end)
    end)
    |> Enum.filter(fn {px, py} ->
      can? = abs(px - x) + abs(py - y) === 1
      # IO.inspect({{x,y}, " -> ", {px, py}, ":", can?})
      can?
    end)

    # only a dif of 1, so up but not left or right as well
  end
end

lines =
  File.stream!("day10.data", :line)
  |> Enum.map(&String.trim/1)

{map, _} =
  Enum.reduce(lines, {%{}, 0}, fn line, {m, y_index} ->
    {m2, _} =
      line
      |> String.to_charlist()
      |> Enum.reduce({m, 0}, fn char, {m1a, x_index} ->
        {char_as_int, _} = Integer.parse(List.to_string([char]))

        m1b = Map.put(m1a, {x_index, y_index}, char_as_int)

        {m1b, x_index + 1}
      end)

    {m2, y_index + 1}
  end)

starting_points =
  Map.keys(map)
  |> Enum.filter(fn key -> map[key] === 0 end)

IO.inspect(starting_points)
max_x = (lines |> hd() |> String.length()) - 1
max_y = Enum.count(lines) - 1

scores =
  starting_points
  |> Enum.map(fn pos ->
    Day10.search(map, max_x, max_y, pos)
  end)

IO.inspect(scores)
IO.inspect(scores |> Enum.reduce(0, &Kernel.+/2))
