defmodule PlantAid.CustomFilters do
  import Ecto.Query

  def datetime_to_date_filter(query, %Flop.Filter{value: value, op: op}, opts) do
    source = Keyword.fetch!(opts, :source)

    expr =
      dynamic(
        [r],
        fragment("?::date", field(r, ^source))
      )

    conditions =
      case op do
        :>= -> dynamic([r], ^expr >= ^value)
        :<= -> dynamic([r], ^expr <= ^value)
        :== -> dynamic([r], ^expr == ^value)
      end

    where(query, ^conditions)
  end
end
