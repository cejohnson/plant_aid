defmodule PlantAid.DiagnosticTests.SelectOption do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :value, :string
  end

  def changeset(option, attrs) do
    option
    |> cast(attrs, [:value])
    |> validate_required([:value])
  end
end
