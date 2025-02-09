defmodule Day25 do
  def solve(path) do
    {locks, keys} = parse(path)

    IO.inspect({MapSet.size(locks), MapSet.size(keys)})

    locks
    |> Enum.reduce(0, fn {l1, l2, l3, l4, l5}, counter ->
      {count, _} = check_keys(keys, {5 - l1, 5 - l2, 5 - l3, 5 - l4, 5 - l5}, MapSet.new())
      counter + count
    end)
  end

  defp check_keys(_, {-1, _, _, _, _}, c), do: {0, c}
  defp check_keys(_, {_, -1, _, _, _}, c), do: {0, c}
  defp check_keys(_, {_, _, -1, _, _}, c), do: {0, c}
  defp check_keys(_, {_, _, _, -1, _}, c), do: {0, c}
  defp check_keys(_, {_, _, _, _, -1}, c), do: {0, c}

  defp check_keys(keys, {k1, k2, k3, k4, k5} = key, checked_keys) do
    case MapSet.member?(checked_keys, key) do
      true ->
        # already checked it, so we dont count this anymore
        {0, checked_keys}

      false ->
        # if a key exists for this lock variation
        fits? = MapSet.member?(keys, {k1, k2, k3, k4, k5})

        val =
          case fits? do
            true -> 1
            false -> 0
          end

        {t1, checked_keys} = check_keys(keys, {k1 - 1, k2, k3, k4, k5}, checked_keys)
        {t2, checked_keys} = check_keys(keys, {k1, k2 - 1, k3, k4, k5}, checked_keys)
        {t3, checked_keys} = check_keys(keys, {k1, k2, k3 - 1, k4, k5}, checked_keys)
        {t4, checked_keys} = check_keys(keys, {k1, k2, k3, k4 - 1, k5}, checked_keys)
        {t5, checked_keys} = check_keys(keys, {k1, k2, k3, k4, k5 - 1}, checked_keys)

        # all the other locks that would work
        val = val + t1 + t2 + t3 + t4 + t5

        {val, MapSet.put(checked_keys, key)}
    end
  end

  defp parse(path) do
    File.read!(path)
    |> String.split("\n\n")
    |> Enum.map(fn rows ->
      rows
      |> String.split("\n")
      |> Enum.reduce({:unknown, {0, 0, 0, 0, 0}}, fn row, {type, hashtags} ->
        chars = String.to_charlist(row)

        type =
          case type do
            :unknown ->
              case List.first(chars) do
                ?# -> :lock
                _ -> :key
              end

            _ ->
              type
          end

        hashtags =
          0..4
          |> Enum.reduce(hashtags, fn index, carry ->
            case Enum.at(chars, index) do
              ?# ->
                value = elem(carry, index)
                put_elem(carry, index, value + 1)

              _ ->
                carry
            end
          end)

        {type, hashtags}
      end)
    end)
    |> Enum.reduce({MapSet.new(), MapSet.new()}, fn {type, {h1, h2, h3, h4, h5}}, {locks, keys} ->
      case type do
        :lock ->
          {MapSet.put(locks, {h1 - 1, h2 - 1, h3 - 1, h4 - 1, h5 - 1}), keys}

        :key ->
          {locks, MapSet.put(keys, {h1 - 1, h2 - 1, h3 - 1, h4 - 1, h5 - 1})}
      end
    end)
  end
end

IO.inspect(Day25.solve("day25.data"))
