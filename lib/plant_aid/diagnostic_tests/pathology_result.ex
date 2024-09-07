defmodule PlantAid.DiagnosticTests.PathologyResult do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "diagnostic_test_pathology_results" do
    field :result, Ecto.Enum, values: [:positive, :negative]

    belongs_to :test_result, PlantAid.DiagnosticTests.TestResult,
      source: :diagnostic_test_result_id

    belongs_to :pathology, PlantAid.Pathologies.Pathology
    belongs_to :genotype, PlantAid.Pathologies.Genotype

    embeds_many :fields, PlantAid.DiagnosticTests.Field, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(pathology_result, attrs) do
    pathology_result
    |> cast(attrs, [:result, :genotype_id])
    |> cast_embed(:fields,
      sort_param: :pathology_field_order,
      delete_param: :pathology_field_delete
    )
  end
end
