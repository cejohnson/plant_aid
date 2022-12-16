defmodule PlantAid.Genomics.Genotype do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "genotypes" do
    field :d13, :string
    field :genotype, :string
    field :gpi, :string
    field :mating_type, :string
    field :mef, :string
    field :mtdna, :string
    field :pep, :string
    field :pi02, :string
    field :pi04, :string
    field :pi16, :string
    field :pi33, :string
    field :pi4b, :string
    field :pi56, :string
    field :pi63, :string
    field :pi70, :string
    field :pi89, :string
    field :pig11, :string
    field :rg57, :string
    field :rg57_band_num, :string

    timestamps()
  end

  @doc false
  def changeset(genotype, attrs) do
    genotype
    |> cast(attrs, [
      :genotype,
      :mating_type,
      :gpi,
      :pep,
      :mef,
      :mtdna,
      :rg57_band_num,
      :rg57,
      :pi02,
      :pi89,
      :pi4b,
      :pig11,
      :pi04,
      :pi70,
      :pi56,
      :pi63,
      :d13,
      :pi16,
      :pi33
    ])
    |> validate_required([
      :genotype,
      :mating_type,
      :gpi,
      :pep,
      :mef,
      :mtdna,
      :rg57_band_num,
      :rg57,
      :pi02,
      :pi89,
      :pi4b,
      :pig11,
      :pi04,
      :pi70,
      :pi56,
      :pi63,
      :d13,
      :pi16,
      :pi33
    ])
  end
end
