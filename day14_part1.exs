defmodule Day14 do
  def solve(filepath, width, height, turns \\ 100) when is_binary(filepath) do
    center_x = floor(width / 2)
    center_y = floor(height / 2)

    read_room_layout(filepath)
    |> Enum.map(fn robot -> simulate(robot, width, height, turns) end)
    |> Enum.reduce(
      %{
        {:top, :left} => 0,
        {:bottom, :left} => 0,
        {:top, :right} => 0,
        {:bottom, :right} => 0
      },
      fn {x, y}, quadrants ->
        case {x, y} do
          {x, y} when x == center_x or y == center_y ->
            quadrants

          {x, y} ->
            qx =
              case center_x > x do
                true -> :top
                false -> :bottom
              end

            qy =
              case center_y > y do
                true -> :left
                false -> :right
              end

            quadrant = {qx, qy}

            count = Map.get(quadrants, quadrant)
            count = count + 1

            Map.put(quadrants, quadrant, count)
        end
      end
    )
    |> Map.values()
    |> Enum.reduce(1, &Kernel.*/2)
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

    IO.inspect({{x, y}, " =[", {vx * turns, vy * turns}, "]=> ", {new_x, new_y}})
    {new_x, new_y}
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

      IO.inspect({first_number, second_number, third_number, fourth_number})

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
IO.inspect(Day14.solve(filepath, width, height, turns))
