defmodule Day17 do
  def parse(filepath) do
    [reg_a, reg_b, reg_c, _, program] =
      File.stream!(filepath)
      |> Enum.to_list()

    {a, _} =
      reg_a
      |> String.split(":")
      |> Enum.at(1)
      |> String.trim()
      |> Integer.parse()

    {b, _} =
      reg_b
      |> String.split(":")
      |> Enum.at(1)
      |> String.trim()
      |> Integer.parse()

    {c, _} =
      reg_c
      |> String.split(":")
      |> Enum.at(1)
      |> String.trim()
      |> Integer.parse()

    pl =
      program
      |> String.split(":")
      |> Enum.at(1)
      |> String.trim()
      |> String.split(",")
      |> Enum.map(&elem(Integer.parse(&1), 0))

    p =
      pl
      |> Enum.with_index()
      |> Enum.map(fn {item, index} -> {index, item} end)
      |> Enum.into(%{})

    {%{
       register_a: a,
       register_b: b,
       register_c: c,
       instruction_pointer: 0,
       program: p,
       output: []
     }, pl}
  end

  def run_program(
        %{
          register_a: _a,
          register_b: _b,
          register_c: _c,
          instruction_pointer: ip,
          program: program,
          output: _output
        } = state
      ) do
    op_code = program[ip]
    operand = program[ip + 1]

    new_state = perform_operation(state, op_code, operand)
    new_instruction_pointer = new_state.instruction_pointer
    instruction_count = Enum.count(Map.keys(new_state.program))

    if new_instruction_pointer >= 0 && new_instruction_pointer < instruction_count do
      run_program(new_state)
    else
      Map.put(new_state, :output, Enum.reverse(new_state.output))
    end
  end

  def combo_operand(state, operand) do
    case operand do
      operand when operand in 0..3 -> operand
      4 -> state.register_a
      5 -> state.register_b
      6 -> state.register_c
    end
  end

  def perform_operation(state, 0, operand) do
    combo_operand = combo_operand(state, operand)
    new_a = floor(state.register_a / :math.pow(2, combo_operand))

    state
    |> Map.put(:register_a, new_a)
    |> Map.put(:instruction_pointer, state.instruction_pointer + 2)
  end

  def perform_operation(state, 1, operand) do
    new_b = Bitwise.bxor(state.register_b, operand)

    state
    |> Map.put(:register_b, new_b)
    |> Map.put(:instruction_pointer, state.instruction_pointer + 2)
  end

  def perform_operation(state, 2, operand) do
    combo_operand = combo_operand(state, operand)

    state
    |> Map.put(:register_b, rem(combo_operand, 8))
    |> Map.put(:instruction_pointer, state.instruction_pointer + 2)
  end

  def perform_operation(state, 3, operand) do
    case state.register_a do
      0 ->
        state
        |> Map.put(:instruction_pointer, state.instruction_pointer + 2)

      _ ->
        state
        |> Map.put(:instruction_pointer, operand)
    end
  end

  def perform_operation(state, 4, _operand) do
    res = Bitwise.bxor(state.register_b, state.register_c)

    state
    |> Map.put(:register_b, res)
    |> Map.put(:instruction_pointer, state.instruction_pointer + 2)
  end

  def perform_operation(state, 5, operand) do
    combo_operand = combo_operand(state, operand)
    out = rem(combo_operand, 8)
    output = state.output

    state
    |> Map.put(:output, [out | output])
    |> Map.put(:instruction_pointer, state.instruction_pointer + 2)
  end

  def perform_operation(state, 6, operand) do
    combo_operand = combo_operand(state, operand)
    new_b = floor(state.register_a / :math.pow(2, combo_operand))

    state
    |> Map.put(:register_b, new_b)
    |> Map.put(:instruction_pointer, state.instruction_pointer + 2)
  end

  def perform_operation(state, 7, operand) do
    combo_operand = combo_operand(state, operand)
    new_c = floor(state.register_a / :math.pow(2, combo_operand))

    state
    |> Map.put(:register_c, new_c)
    |> Map.put(:instruction_pointer, state.instruction_pointer + 2)
  end

  def find_other_solution(original_state, search, index \\ 0) do
    indexes = index..(index + 99)
    skip = original_state.register_a

    result =
      indexes
      |> Enum.filter(fn value -> value != skip end)
      |> Enum.map(fn reg_a ->
        Task.async(fn ->
          res = Day17.run_program(Map.put(original_state, :register_a, reg_a))
          {res.output == search, reg_a}
        end)
      end)
      |> Enum.map(fn task -> Task.await(task, 10_000) end)
      |> Enum.find(fn {found?, _reg_val} -> found? end)

    case result do
      {true, _} -> result
      _ -> find_other_solution(original_state, search, index + 100)
    end
  end
end

# program_state = Day17.parse("day17.data")
{program_state, program_instructions} = Day17.parse("day17.data")

IO.inspect({"searching", program_instructions})

{found?, reg_a} = Day17.find_other_solution(program_state, program_instructions)
IO.inspect({"solution?", found?, reg_a})
