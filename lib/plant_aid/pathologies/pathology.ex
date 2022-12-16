defmodule PlantAid.Pathologies.Pathology do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "pathologies" do
    field :common_name, :string
    field :scientific_name, :string

    timestamps()
  end

  @doc false
  def changeset(pathology, attrs) do
    pathology
    |> cast(attrs, [:common_name, :scientific_name])
    |> validate_required([:common_name, :scientific_name])
  end
end
