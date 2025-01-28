defmodule Day19 do
  def parse_input(path) do
    {towels, patterns, _} =
      File.stream!(path, :line)
      |> Enum.reduce({[], [], :towels}, fn line, {towels, patterns, mode} ->
        case mode do
          :towels ->
            towels =
              line
              |> String.split(", ")
              |> Enum.map(&String.trim/1)

            {towels, patterns, :nothing}

          :nothing ->
            {towels, patterns, :patterns}

          :patterns ->
            {towels, [String.trim(line) | patterns], :patterns}
        end
      end)

    {towels, patterns}
  end

  def is_pattern_possible?("", _), do: true

  def is_pattern_possible?(pattern, towels) do
    suitable_towels =
      towels
      |> Enum.filter(fn towel -> String.starts_with?(pattern, towel) end)

    case Enum.empty?(suitable_towels) do
      true ->
        # pattern not empty, but nothing would fit in
        false

      false ->
        suitable_towels
        |> Enum.reduce(false, fn towel, possible? ->
          case possible? do
            true ->
              true

            false ->
              pattern_length = String.length(pattern)
              towel_length = String.length(towel)
              remaining_pattern = String.slice(pattern, towel_length, pattern_length - towel_length)

              is_pattern_possible?(remaining_pattern, towels)
          end
        end)
    end
  end
end

{towels, patterns} = Day19.parse_input("day19.data")

result = patterns
|> Enum.reverse()
|> Enum.map(fn pattern ->
  {Day19.is_pattern_possible?(pattern, towels), pattern}
end)

# IO.inspect(result)
IO.inspect(result |> Enum.filter(fn {ok, _} -> ok end) |> Enum.count())
