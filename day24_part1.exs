defmodule Day24 do
  def solve(path) do
    {:ok, content} = File.read(path)

    [wires, gates] =
      content
      |> String.split("\n\n")

    wires = wires
    |> String.split("\n")
    |> Enum.reduce(%{}, fn str, wires ->
      [wire_name, value] = str |> String.split(": ")
      {value, _} = Integer.parse(value)

      Map.put(wires, wire_name, value)
    end)

    gates = gates
    |> String.split("\n")
    |> Enum.reduce(%{}, fn g, carry ->
      [wire1, operator, wire2, _, resulting_wires] = String.split(g, " ")

      Map.put(carry, resulting_wires, {wire1, operator, wire2})
    end)


    wires = solve_gates(wires, gates)

    wires
    |> Enum.filter(fn {key, _}-> String.starts_with?(key, "z") end)
    |> Enum.sort(:desc)
    |> Enum.map(&elem(&1, 1))
    |> Enum.reduce(0, fn bit, num ->
      Bitwise.bsl(num, 1) + bit
    end)

  end

  def solve_gates(wires, gates) do
    gate_keys = Map.keys(gates)

    case gate_keys do
      [] ->
        wires

      _gates ->
        known = Map.keys(wires)

        solved_gates =
          gates
          |> Enum.filter(fn {_key, {w1, _op, w2}} ->
            Enum.member?(known, w1) and Enum.member?(known, w2)
          end)
          |> Enum.map(fn {gate, {w1, operand, w2}} ->
            v1 = wires[w1]
            v2 = wires[w2]

            {gate, apply_operand(operand, v1, v2)}
          end)

        gates = Map.drop(gates, solved_gates |> Enum.map(&elem(&1, 0)))

        wires =
          solved_gates
          |> Enum.reduce(wires, fn {key, value}, wiress ->
            Map.put(wiress, key, value)
          end)

        solve_gates(wires, gates)
    end
  end

  def apply_operand("XOR", 1, 0), do: 1
  def apply_operand("XOR", 0, 1), do: 1
  def apply_operand("XOR", _, _), do: 0

  def apply_operand("AND", 1, 1), do: 1
  def apply_operand("AND", _, _), do: 0

  def apply_operand("OR", 0, 0), do: 0
  def apply_operand("OR", _, _), do: 1
end

IO.inspect(Day24.solve("day24.data"))
