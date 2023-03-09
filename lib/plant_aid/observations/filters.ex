defmodule PlantAid.Observations.Filters do
  import Ecto.Query, warn: false

  def group_by(query, %Flop.Filter{value: value, op: op}, opts) do
    IO.inspect(query, label: "query")
    IO.inspect(value, label: "value")
    IO.inspect(op, label: "op")

    observation_count_query =
      from(
        o in query,
        where: parent_as(:ssd).id == o.secondary_subdivision_id,
        # group_by: o.secondary_subdivision_id,
        select: %{count: count(o.id)}
      )

    from(
      ssd in PlantAid.Geography.SecondarySubdivision,
      as: :ssd,
      inner_lateral_join: oc in subquery(observation_count_query),
      select: %{ssd | observation_count: oc.count}
    )
  end
end
