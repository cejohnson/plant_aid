defmodule PlantAid.Pathologies.Genotype do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "genotypes" do
    field :name, :string

    belongs_to :pathology, PlantAid.Pathologies.Pathology

    timestamps()
  end

  @doc false
  def changeset(genotype, %{"delete" => "true"}) do
    %{Ecto.Changeset.change(genotype) | action: :delete}
  end

  def changeset(genotype, attrs) do
    genotype
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
