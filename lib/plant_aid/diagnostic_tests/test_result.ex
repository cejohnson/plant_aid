defmodule PlantAid.DiagnosticTests.TestResult do
  use Ecto.Schema
  import Ecto.Changeset
  alias PlantAid.Accounts.User

  alias PlantAid.DiagnosticTests.Field
  alias PlantAid.DiagnosticTests.PathologyResult

  @timestamps_opts [type: :utc_datetime]

  @derive {
    Flop.Schema,
    filterable: [
      :id,
      :observation_date,
      :updated_on,
      :result,
      :pathology_id,
      :genotype_id,
      :host_id
    ],
    sortable: [
      :id,
      :observation_date,
      :updated_at
    ],
    adapter_opts: [
      join_fields: [
        result: [
          binding: :pathology_results,
          field: :result,
          ecto_type: {:ecto_enum, [positive: "positive", negative: "negative"]}
        ],
        pathology_id: [
          binding: :pathology_results,
          field: :pathology_id
        ],
        genotype_id: [
          binding: :pathology_results,
          field: :genotype_id
        ],
        host_id: [
          binding: :observation,
          field: :host_id
        ],
        observation_date: [
          binding: :observation,
          field: :observation_date
        ]
      ],
      custom_fields: [
        updated_on: [
          filter: {PlantAid.CustomFilters, :datetime_to_date_filter, [source: :updated_at]},
          ecto_type: :date,
          operators: [:<=, :>=]
        ]
      ]
    ],
    default_order: %{
      order_by: [:updated_at],
      order_directions: [:desc_nulls_last]
    }
  }

  schema "diagnostic_test_results" do
    field :metadata, :map
    field :comments, :string

    belongs_to :inserted_by, User
    belongs_to :updated_by, User
    belongs_to :observation, PlantAid.Observations.Observation
    belongs_to :diagnostic_method, PlantAid.DiagnosticMethods.DiagnosticMethod

    has_many :pathology_results, PathologyResult, on_replace: :delete

    embeds_many :fields, Field, on_replace: :delete

    timestamps()
  end

  defmodule Overrides do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      embeds_many :fields, Field
      embeds_many :pathology_results, PathologyResult
    end
  end

  @doc false
  def changeset(test_result, attrs) do
    test_result
    |> cast(attrs, [:comments, :observation_id, :diagnostic_method_id])
    |> validate_required([:observation_id, :diagnostic_method_id])
    |> foreign_key_constraint(:observation_id)
    |> foreign_key_constraint(:diagnostic_method_id)
    |> cast_embed(:fields)
    |> cast_assoc(:pathology_results)
  end

  def changeset(test_result, nil, attrs) do
    changeset(test_result, attrs)
  end

  def changeset(test_result, overrides, attrs) do
    changeset =
      test_result
      |> cast(attrs, [:comments, :observation_id, :diagnostic_method_id])
      |> validate_required([:observation_id, :diagnostic_method_id])
      |> foreign_key_constraint(:observation_id)
      |> foreign_key_constraint(:diagnostic_method_id)

    fields =
      overrides.fields
      |> Enum.with_index(fn field, index ->
        attrs = get_in(attrs, ["fields", Integer.to_string(index)]) || %{}
        Field.changeset(field, attrs)
      end)

    pathology_results =
      overrides.pathology_results
      |> Enum.with_index(fn pathology_result, pathology_result_index ->
        fields =
          pathology_result.fields
          |> Enum.with_index(fn field, field_index ->
            attrs =
              get_in(attrs, [
                "pathology_results",
                Integer.to_string(pathology_result_index),
                "fields",
                Integer.to_string(field_index)
              ]) || %{}

            Field.changeset(field, attrs)
          end)

        attrs =
          get_in(attrs, ["pathology_results", Integer.to_string(pathology_result_index)]) || %{}

        PathologyResult.changeset(pathology_result, attrs)
        |> put_embed(:fields, fields)
      end)

    changeset
    |> put_embed(:fields, fields)
    |> put_assoc(:pathology_results, pathology_results)
  end
end
