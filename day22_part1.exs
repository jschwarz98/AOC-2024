defmodule Day22 do
  def step1(secret_number) when is_integer(secret_number) do
    t1 = secret_number * 64
    t2 = Bitwise.bxor(secret_number, t1)
    rem(t2, 16_777_216)
  end

  def step2(secret_number) when is_integer(secret_number) do
    t1 = floor(secret_number / 32)
    t2 = Bitwise.bxor(t1, secret_number)
    rem(t2, 16_777_216)
  end

  def step3(secret_number) when is_integer(secret_number) do
    t1 = secret_number * 2048
    t2 = Bitwise.bxor(t1, secret_number)
    rem(t2, 16_777_216)
  end

  def pipeline(secret_number) do
    secret_number
    |> step1()
    |> step2()
    |> step3()
  end

  def next_x_numbers(secret_number, steps) when is_integer(secret_number) and steps >= 1 do
    {_last, numbers} =
      1..steps
      |> Enum.reduce({secret_number, []}, fn _step, {number, numbers} ->
        new_secret_number = pipeline(number)

        {new_secret_number, [new_secret_number | numbers]}
      end)

    numbers
  end

  def solve(path) do
    File.stream!(path)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&Integer.parse/1)
    |> Enum.map(&elem(&1, 0))
    |> Enum.map(&next_x_numbers(&1, 2000))
    |> Enum.map(&List.first/1)
    |> Enum.reduce(0, &Kernel.+/2)
  end
end

IO.inspect(Day22.solve("day22.data"))
