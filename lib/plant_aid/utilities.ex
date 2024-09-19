defmodule PlantAid.Utilities do
  def pretty_print(term) when is_atom(term) do
    term
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def english_join(list, conjunction, opts \\ []) do
    max_length = Keyword.get(opts, :max_length, 4)
    excess_descriptor = Keyword.get(opts, :excess_descriptor, "others")
    include_excess_count = Keyword.get(opts, :include_excess_count, true)

    join(list, conjunction, max_length, excess_descriptor, include_excess_count)
  end

  defp join([], _, _, _, _) do
    ""
  end

  defp join([first | []], _, _, _, _) do
    first
  end

  defp join([first | [last]], conjunction, _, _, _) do
    "#{first} #{conjunction} #{last}"
  end

  defp join(list, conjunction, max_length, _, _) when length(list) <= max_length do
    [last | rest] = Enum.reverse(list)

    (rest
     |> Enum.reverse()
     |> Enum.join(", ")) <> ", #{conjunction} #{last}"
  end

  defp join(list, conjunction, max_length, excess_descriptor, include_excess_count) do
    {to_print, excess} = Enum.split(list, max_length - 1)

    excess_phrase =
      if include_excess_count do
        "#{length(excess)} #{excess_descriptor}"
      else
        excess_descriptor
      end

    Enum.join(to_print, ", ") <> ", #{conjunction} #{excess_phrase}"
  end
end
