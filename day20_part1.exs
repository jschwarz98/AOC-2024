defmodule Day20 do
  def parse_map(path) do
    {map, max_x, max_y_plus_one} =
      File.stream!(path, :line)
      |> Enum.map(&String.trim/1)
      |> Enum.reduce({%{}, 0, 0}, fn line, {map, _max_x, y} ->
        {updated_map, max_x_plus_one} =
          String.to_charlist(line)
          |> Enum.reduce({map, 0}, fn char, {m, x} ->
            {Map.put(m, {x, y}, char), x + 1}
          end)

        {updated_map, max_x_plus_one - 1, y + 1}
      end)

    {map, max_x, max_y_plus_one - 1}
  end

  def map_out_the_track(
        map,
        {x, y} = current_pos,
        goal,
        came_from \\ nil,
        steps \\ %{},
        steps_taken \\ 0
      ) do
    next_neighbour =
      [
        {x - 1, y},
        {x, y - 1},
        {x + 1, y},
        {x, y + 1}
      ]
      |> Enum.filter(fn coordinate ->
        char = Map.get(map, coordinate)

        char != ?# and char != nil and coordinate != came_from
      end)
      |> List.first()

    updated_steps = Map.put(steps, next_neighbour, {current_pos, steps_taken + 1})

    case next_neighbour do
      ^goal ->
        updated_steps

      n ->
        map_out_the_track(map, n, goal, current_pos, updated_steps, steps_taken + 1)
    end
  end

  def find_cheats(map, {x, y} = position, steps, threshhold \\ 100, found \\ 0) do
    {next_pos, steps_to_goal} = info = steps[position]

    case steps_to_goal < threshhold do
      true ->
        found

      false ->
        possible_cheats =
          [
            {{x - 1, y}, {x - 2, y}},
            {{x, y - 1}, {x, y - 2}},
            {{x + 1, y}, {x + 2, y}},
            {{x, y + 1}, {x, y + 2}}
          ]
          |> Enum.filter(fn {c1, c2} ->
            char1 = map[c1]
            char2 = map[c2]
            char1 == ?# and char2 != nil and char2 != ?#
          end)

        worthwhile_cheats =
          possible_cheats
          |> Enum.map(fn {_, c2} ->
            {_next_pos, cost} = steps[c2]
            # +2 because we walk through the wall
            cost + 2
          end)
          |> Enum.filter(fn cost ->
            valid? = cost < steps_to_goal and steps_to_goal - cost >= threshhold
            valid?
          end)
          |> Enum.count()

        # todo check all the surrounding walls for possible cheats and check where we end up
        updated_found = found + worthwhile_cheats
        find_cheats(map, next_pos, steps, threshhold, updated_found)
    end
  end
end

{map, _max_x, _max_y} = Day20.parse_map("day20.data")

{start, {gx, gy} = goal} =
  map
  |> Enum.reduce({{0, 0}, {0, 0}}, fn {coord, char}, {s, g} = carry ->
    case char do
      ?S -> {coord, g}
      ?E -> {s, coord}
      _ -> carry
    end
  end)

steps_to_take = Day20.map_out_the_track(map, goal, start)
steps_to_take = Map.put(steps_to_take, goal, {nil, 0})

steps_sorted =
  steps_to_take
  |> Enum.sort_by(fn {_key, {_next, amount_of_steps}} -> amount_of_steps end, :desc)

IO.puts(
  (steps_sorted
   |> Enum.filter(fn {_, {a, _}} -> a != nil end)
   |> Enum.map(fn {{x, y}, {{nx, ny}, steps_to_goal}} ->
     "[#{x};#{y}] => [#{nx};#{ny}] ~ #{steps_to_goal} steps"
   end)
   |> Enum.join("\n")) <>
    "\n[#{gx};#{gy}] => [goal] ~ 0 steps"
)

IO.puts("")
IO.puts("can save at least x steps with y cheats:")
IO.inspect(Day20.find_cheats(map, start, steps_to_take, 100))
