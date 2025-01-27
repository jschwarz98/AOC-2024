defmodule Day18 do
  def read_input(path) do
    File.stream!(path, :line)
    |> Enum.map(&String.split(&1, ","))
    |> Enum.map(fn [x, y] -> {elem(Integer.parse(x), 0), elem(Integer.parse(y), 0)} end)
  end

  def create_grid(coords, steps) do
    coords
    |> Enum.take(steps)
    |> Enum.reduce(%{}, fn coordinate, map ->
      Map.put(map, coordinate, :corrupted)
    end)
  end

  def visualize_grid(grid, max_x, max_y) do
    0..max_y
    |> Enum.reduce([], fn y, lines ->
      line =
        0..max_x
        |> Enum.reduce("", fn x, line ->
          case grid[{x, y}] do
            :corrupted -> line <> "#"
            :path -> line <> "O"
            _ -> line <> "."
          end
        end)

      [line | lines]
    end)
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  def find_path(map, start, goal, heuristic, max_x, max_y)
      when is_function(heuristic) and is_map(map) and is_tuple(start) and is_tuple(goal) do
    open_set = MapSet.new([start])

    came_from = %{start => nil}

    g_score = %{start => 0}
    f_score = %{start => heuristic.(start, goal)}

    a_star(map, max_x, max_y, goal, heuristic, open_set, came_from, g_score, f_score)
  end

  defp a_star(map, max_x, max_y, goal, heuristic, open_set, came_from, g_score, f_score) do
    nodes =
      open_set
      |> MapSet.to_list()

    current =
      case nodes do
        [] ->
          nil

        nodes ->
          nodes
          |> Enum.min_by(&f_score[&1])
      end

    case current do
      ^goal ->
        reconstruct_path(current, came_from)

      nil ->
        :failure

      _ ->
        open_set = MapSet.delete(open_set, current)

        {x, y} = current

        neighbours =
          [
            {x - 1, y},
            {x + 1, y},
            {x, y - 1},
            {x, y + 1}
          ]
          |> Enum.filter(fn {nx, ny} = coord ->
            nx >= 0 and nx <= max_x and ny >= 0 and ny <= max_y and map[coord] != :corrupted
          end)

        {updated_open_set, updated_came_from, updated_g_score, updated_f_score} =
          neighbours
          |> Enum.reduce(
            {open_set, came_from, g_score, f_score},
            fn neighbour,
               {updated_open_set, updated_came_from, updated_g_score, updated_f_score} ->
              # 1 == distance from current to neighbour
              potential_neighbour_g_score = updated_g_score[current] + 1

              current_neighbour_g_score =
                case updated_g_score[neighbour] do
                  nil -> 100_000_000
                  value -> value
                end

              shorter_path? = potential_neighbour_g_score < current_neighbour_g_score

              case shorter_path? do
                true ->
                  {MapSet.put(updated_open_set, neighbour),
                   Map.put(updated_came_from, neighbour, current),
                   Map.put(updated_g_score, neighbour, potential_neighbour_g_score),
                   Map.put(
                     updated_f_score,
                     neighbour,
                     potential_neighbour_g_score + heuristic.(neighbour, goal)
                   )}

                false ->
                  {updated_open_set, updated_came_from, updated_g_score, updated_f_score}
              end
            end
          )

        a_star(
          map,
          max_x,
          max_y,
          goal,
          heuristic,
          updated_open_set,
          updated_came_from,
          updated_g_score,
          updated_f_score
        )
    end
  end

  defp reconstruct_path(current, came_from) do
    reconstruct_path(current, came_from, [current])
  end

  defp reconstruct_path(current, came_from, path) do
    prev = came_from[current]

    case prev do
      nil ->
        path

      _ ->
        reconstruct_path(prev, came_from, [prev | path])
    end
  end
end

max_x = 70
max_y = 70

coordinates = Day18.read_input("day18.data")

coordinate = 1024..length(coordinates)
|> Enum.reduce(nil, fn steps, critical_coordinate ->
  case critical_coordinate do
    nil ->
      map = Day18.create_grid(coordinates, steps)
      IO.puts(Day18.visualize_grid(map, max_x, max_y))

      path =
        Day18.find_path(
          map,
          {0, 0},
          {max_x, max_y},
          fn {x1, y1}, {x2, y2} -> abs(x2 - x1 + y2 - y1) end,
          max_x,
          max_y
        )

      case path do
        :failure -> Enum.at(coordinates, steps - 1)
        _ -> nil
      end
    _ ->
      critical_coordinate
  end
end)

IO.inspect(coordinate)
