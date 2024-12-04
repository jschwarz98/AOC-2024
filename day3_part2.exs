defmodule Day3 do
  def doDontParser(line, enabled \\ true) do
    traverse(line, "", 0, enabled)
  end

  defp is_next_letter?(letter, value_so_far, target_string) do
    len = String.length(value_so_far)
    String.at(target_string, len) == letter
  end

  defp traverse("", _, value, enabled) do
    {value, enabled}
  end

  defp traverse(string, seen, value, enabled) do
    letter = String.first(string)
    rest = String.slice(string, 1..-1//1)

    {seen, value, enabled} =
      case enabled do
        true ->
          case String.starts_with?(seen, "mul(") do
            true ->
              seen = seen <> letter

              completed = ~r/^mul\([0-9]{1,3},[0-9]{1,3}\)$/
              second_number = ~r/^mul\([0-9]{1,3},[0-9]{1,3}$/
              comma = ~r/^mul\([0-9]{1,3},$/
              first_number = ~r/^mul\([0-9]{1,3}$/

              case Regex.match?(completed, seen) do
                true ->
                  {"", value + Day3.parseMuls(seen), enabled}

                false ->
                  still_valid? =
                    [second_number, comma, first_number]
                    |> Enum.reduce(false, fn val, carry -> carry or Regex.match?(val, seen) end)

                  case still_valid? do
                    true ->
                      {seen, value, enabled}

                    false ->
                      {"", value, enabled}
                  end
              end

            false ->
              case is_next_letter?(letter, seen, "don't()") do
                true ->
                  seen = seen <> letter

                  case seen == "don't()" do
                    true ->
                      {"", value, false}

                    false ->
                      {seen, value, enabled}
                  end

                false ->
                  case is_next_letter?(letter, seen, "mul(") do
                    true ->
                      seen = seen <> letter
                      {seen, value, enabled}

                    false ->
                      {"", value, enabled}
                  end
              end
          end

        false ->
          ## check for do
          case is_next_letter?(letter, seen, "do()") do
            true ->
              seen = seen <> letter

              case seen == "do()" do
                true -> {"", value, true}
                false -> {seen, value, enabled}
              end

            false ->
              {"", value, enabled}
          end
      end

    traverse(rest, seen, value, enabled)
  end

  def parseMuls(line) do
    Regex.scan(~r/mul\([0-9]{1,3},[0-9]{1,3}\)/, line)
    |> Enum.flat_map(fn i -> i end)
    |> Enum.map(fn i ->
      i
      |> String.slice(4..-2//1)
      |> String.split(",")
      |> Enum.map(fn n ->
        {int, _} = Integer.parse(n)
        int
      end)
      |> Enum.reduce(fn a, b -> a * b end)
    end)
    |> Enum.reduce(&Kernel.+/2)
  end
end

# day3.debug2.data
# day3.debug.data
# day3.data
{result, _} =
  File.stream!("./day3.data", :line)
  |> Enum.reduce({0, true}, fn line, {value, enabled} ->
    IO.inspect(
      "calling with reading enabled? " <>
        case enabled do
          true -> "yes"
          false -> "no"
        end
    )

    {value_of_line, ended_enabled} = Day3.doDontParser(line, enabled)
    IO.inspect({value_of_line, ended_enabled})
    {value_of_line + value, ended_enabled}
  end)

IO.inspect(result)
