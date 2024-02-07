defmodule PlantAid.Pathologies.Pathology do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "pathologies" do
    field :common_name, :string
    field :scientific_name, :string

    has_many :genotypes, PlantAid.Pathologies.Genotype, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(pathology, attrs) do
    pathology
    |> cast(attrs, [:common_name, :scientific_name])
    |> validate_required([:common_name, :scientific_name])
    |> cast_assoc(:genotypes, sort_param: :genotypes_order, drop_param: :genotypes_delete)
  end
end
