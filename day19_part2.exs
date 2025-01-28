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

  def count_solutions("", _, _), do: 1

  def count_solutions(pattern, towels, solution_agent) do
    suitable_towels =
      towels
      |> Enum.filter(fn towel -> String.starts_with?(pattern, towel) end)

    case Enum.empty?(suitable_towels) do
      true ->
        # pattern not empty, but nothing would fit in
        0

      false ->
        amount_solutions =
          Agent.get(solution_agent, fn solutions -> Map.get(solutions, pattern) end)

        case amount_solutions do
          nil ->
            solutions_for_pattern =
              suitable_towels
              |> Enum.reduce(0, fn towel, solutions ->
                pattern_length = String.length(pattern)
                towel_length = String.length(towel)

                remaining_pattern =
                  String.slice(pattern, towel_length, pattern_length - towel_length)

                solutions + count_solutions(remaining_pattern, towels, solution_agent)
              end)

            :ok = Agent.update(solution_agent, fn solutions ->
              Map.put(solutions, pattern, solutions_for_pattern)
            end)

            solutions_for_pattern

          _ ->
            amount_solutions
        end
    end
  end
end

{towels, patterns} = Day19.parse_input("day19.data")
# agent to cache results
{:ok, solution_agent} = Agent.start_link(fn -> %{} end)

# agent to track total completions
{:ok, progress_agent} = Agent.start_link(fn -> 0 end)
total_patterns = length(patterns)

result =
  patterns
  |> Enum.reverse()
  |> Enum.map(fn pattern ->
    Task.async(fn ->
      solutions = Day19.count_solutions(pattern, towels, solution_agent)

      completed_tasks =
        Agent.get_and_update(progress_agent, fn count ->
          new_count = count + 1
          {new_count, new_count}
        end)

      # Output the progress
      IO.puts("Progress: #{completed_tasks}/#{total_patterns} tasks completed")

      {solutions, pattern}
    end)
  end)
  |> Enum.map(&Task.await(&1, :infinity))

IO.inspect(result |> Enum.map(fn {c, _} -> c end) |> Enum.reduce(0, &Kernel.+/2))
