defmodule Day21 do
  def initial_state() do
    %{
      # robot 1
      num_pad: num_pad(),
      # robot 2
      dir_pad1: dir_pad(),
      # me
      dir_pad2: dir_pad()
    }
  end

  defp dir_pad do
    %{
      :avoid => {0, 0},
      ?^ => {1, 0},
      ?A => {2, 0},
      ?< => {0, 1},
      ?v => {1, 1},
      ?> => {2, 1},
      :position => {2, 0}
    }
  end

  defp num_pad do
    %{
      ?7 => {0, 0},
      ?8 => {1, 0},
      ?9 => {2, 0},
      ?4 => {0, 1},
      ?5 => {1, 1},
      ?6 => {2, 1},
      ?1 => {0, 2},
      ?2 => {1, 2},
      ?3 => {2, 2},
      :avoid => {0, 3},
      ?0 => {1, 3},
      ?A => {2, 3},
      :position => {2, 3}
    }
  end

  def input(
        %{
          num_pad: num,
          dir_pad1: dir1,
          dir_pad2: dir2
        },
        code
      ) do
    # try to go through each pad, basically iterating, and get the needed inputs per pad, for the previous input
    # so, we check what moves we need to make for num_pad, then use that to check what dir_pad1 needs to press,
    # feed that into pad2, and then thats our result

    # pressed for robot 1 to make:
    num_pad_inputs = solve(num, code |> String.to_charlist())
    IO.inspect({"step1", num_pad_inputs})

    # presses for robot 2 to press to robot 1 can make the correct moves:
    robot1_inputs = solve(dir1, num_pad_inputs |> String.to_charlist())
    IO.inspect({"step2", robot1_inputs})

    # presses for me so robot 2 can make the correct moves:
    robot2_inputs = solve(dir2, robot1_inputs |> String.to_charlist())
    IO.inspect({"step3", robot2_inputs})

    # my_inputs = solve(dir2, robot2_inputs |> String.to_charlist())
    # IO.inspect({"step4", my_inputs})
    # my_inputs
    robot2_inputs
  end

  defp solve(%{} = pad, inputs) when is_list(inputs), do: solve(pad, inputs, "")

  defp solve(pad, [input | inputs], commands) do
    target_position = pad[input]
    presses = resolve(pad, target_position)
    solve(Map.put(pad, :position, target_position), inputs, commands <> presses)
  end

  defp solve(_map, [], commands), do: commands

  defp find_shortest_inputs_for_chunk(pad, chunk) do
    freqs = Enum.frequencies(chunk)

    # we check if its faster to press x or y axis first from our current position
  end

  defp resolve(%{} = pad, {tx, ty}) do
    {_ax, ay} = pad[:avoid]
    {x, y} = pad[:position]

    y_diff = ty - y
    x_diff = tx - x

    y_movement =
      case y_diff do
        0 ->
          ""

        y_diff when y_diff < 0 ->
          # move up
          String.duplicate("^", abs(y_diff))

        y_diff when y_diff > 0 ->
          # move down
          String.duplicate("v", y_diff)
      end

    x_movement =
      case x_diff do
        0 ->
          ""

        x_diff when x_diff < 0 ->
          # move left
          String.duplicate("<", abs(x_diff))

        x_diff when x_diff > 0 ->
          # move right
          String.duplicate(">", x_diff)
      end

    case y do
      ^ay ->
        # y axis first, then x-axis
        y_movement <> x_movement <> "A"

      _ ->
        # x-axis first, then y axis
        x_movement <> y_movement <> "A"
    end
  end

  def calc_complexity(code, result) do
    {factor, _} = Integer.parse(code)

    IO.inspect({code, "=>", String.length(result), "*", factor})
    String.length(result) * factor
  end
end

total_complexity =
  File.stream!("zzzz.data")
  |> Enum.map(&String.trim/1)
  |> Enum.map(fn code ->
    state = Day21.initial_state()
    result = Day21.input(state, code)
    complexity = Day21.calc_complexity(code, result)
    IO.inspect({"resulting complexity", code, complexity})
    complexity
  end)
  |> Enum.reduce(0, &Kernel.+/2)

IO.inspect({"total complexity: ", total_complexity})

# v<<A>>^A<A>AvA<^AA>A<vAAA>^A
# v<<A>>^A<A>A<AAv>A^Av<AAA^>A

#<vA<AA>>^AvAA<^A>A<v<A>>^AvA^A<vA>^A<v<A>^A>AAvA^A<v<A>A>^AAAvA<^A>A
#v<A<AA>>^AvAA^<A>Av<<A>>^AvA^Av<<A>>^AAv<A>A^A<A>Av<A<A>>^AAA<Av>A^A
