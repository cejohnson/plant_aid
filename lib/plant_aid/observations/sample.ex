defmodule PlantAid.Observations.Sample do
  use Ecto.Schema
  import Ecto.Changeset

  schema "samples" do
    field :result, Ecto.Enum, values: [:positive, :negative, :indeterminate]
    field :confidence, :float
    field :comments, :string
    field :metadata, :map

    belongs_to :observation, PlantAid.Observations.Observation
    belongs_to :pathology, PlantAid.Pathologies.Pathology
    belongs_to :genotype, PlantAid.Pathologies.Genotype

    embeds_many :data, KeyValuePair, on_replace: :delete do
      field :key, :string
      field :value, :string
    end

    timestamps()
  end

  @doc false
  def changeset(sample, attrs) do
    sample
    |> cast(attrs, [:result, :confidence, :comments, :pathology_id, :genotype_id])
    |> validate_number(:confidence, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    # |> cast_assoc(:pathology_id)
    # |> cast_assoc(:genotype_id)
    |> cast_embed(:data,
      with: &data_changeset/2,
      sort_param: :data_order,
      drop_param: :data_delete
    )
  end

  defp data_changeset(data, attrs) do
    data
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
  end
end
