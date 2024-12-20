defmodule Day14 do
  def solve(filepath, width, height, turns \\ 10_000_000) when is_binary(filepath) do
    read_room_layout(filepath)
    |> step_through_simulation(width, height, 0)
  end

  defp step_through_simulation(robots, _, _, 10_001), do: robots

  defp step_through_simulation(robots, width, height, step) do
    step = step + 1
    center_x = floor(width / 2)
    center_y = floor(height / 2)
    robots = robots |> Enum.map(fn robot -> simulate(robot, width, height, 1) end)

    heuristic =
      robots
      |> Enum.map(fn {x, y, _, _} ->
        # how far away from the center
        abs(x - center_x) + abs(y - center_y)
      end)
      |> Enum.reduce(0, &Kernel.+/2)

    if heuristic < 19_000 do
      IO.puts("----")
      IO.inspect({"STEP", step, "ENTROPY", heuristic})
      map = generate_map(robots, width, height)
      render_map(map, width, height)
    end

    step_through_simulation(robots, width, height, step)
  end

  defp generate_map(robots, width, height) do
    map =
      0..(width - 1)
      |> Enum.reduce(%{}, fn x, map ->
        0..(height - 1)
        |> Enum.reduce(map, fn y, map ->
          Map.put(map, {x, y}, " ")
        end)
      end)

    robots
    |> Enum.reduce(map, fn {x, y, _, _}, map ->
      Map.put(map, {x, y}, "#")
    end)
  end

  defp render_map(map, width, height) do
    lines =
      0..(height - 1)
      |> Enum.reduce([], fn y, lines ->
        line =
          0..(width - 1)
          |> Enum.reduce("", fn x, line ->
            line <> map[{x, y}]
          end)

        [line | lines]
      end)
      |> Enum.reverse()
      |> Enum.join("\n")

    IO.puts(lines)
  end

  defp simulate({x, y, vx, vy}, width, height, turns) do
    new_x = x + vx * turns

    new_x =
      case new_x do
        new_x when new_x >= width -> Integer.mod(new_x, width)
        new_x when new_x < 0 -> Integer.mod(width - Integer.mod(abs(new_x), width), width)
        _ -> new_x
      end

    new_y = y + vy * turns

    new_y =
      case new_y do
        new_y when new_y >= height -> Integer.mod(new_y, height)
        new_y when new_y < 0 -> Integer.mod(height - Integer.mod(abs(new_y), height), height)
        _ -> new_y
      end

    {new_x, new_y, vx, vy}
  end

  defp read_room_layout(filepath) do
    File.stream!(filepath, :line)
    |> Enum.map(fn line ->
      # "p=0,4 v=3,-3"

      [_, first_number] = String.split(line, "=", parts: 2)
      [first_number, rest] = String.split(first_number, ",", parts: 2)
      [second_number, rest] = String.split(rest, " ", parts: 2)

      [_, third_number] = String.split(rest, "=", parts: 2)
      [third_number, fourth_number] = String.split(third_number, ",", parts: 2)

      {x, _} = Integer.parse(first_number)
      {y, _} = Integer.parse(second_number)
      {vx, _} = Integer.parse(third_number)
      {vy, _} = Integer.parse(fourth_number)

      {x, y, vx, vy}
    end)
  end
end

[filepath, width_str, height_str, turn_str] = System.argv()
{width, _} = Integer.parse(width_str)
{height, _} = Integer.parse(height_str)
{turns, _} = Integer.parse(turn_str)
IO.inspect({"path", filepath, "width", width, "height", height, "turns", turns})
Day14.solve(filepath, width, height, turns)
