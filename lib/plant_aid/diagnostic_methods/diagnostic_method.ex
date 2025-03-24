defmodule PlantAid.DiagnosticMethods.DiagnosticMethod do
  use Ecto.Schema
  import Ecto.Changeset
  alias PlantAid.Accounts.User
  alias PlantAid.DiagnosticMethods.Field

  @timestamps_opts [type: :utc_datetime]

  schema "diagnostic_methods" do
    field :name, :string
    field :description, :string

    belongs_to :inserted_by, User
    belongs_to :updated_by, User

    many_to_many :pathologies, PlantAid.Pathologies.Pathology,
      join_through: "diagnostic_methods_pathologies",
      on_replace: :delete

    field :pathology_ids, {:array, :integer}, virtual: true

    embeds_many :fields, Field, on_replace: :delete

    has_many :diagnostic_test_results, PlantAid.DiagnosticTests.TestResult

    timestamps()
  end

  @doc false
  def changeset(diagnostic_method, attrs) do
    diagnostic_method
    |> cast(attrs, [:name, :description, :pathology_ids])
    |> validate_required([:name])
    |> unique_constraint([:name])
    |> cast_embed(:fields,
      sort_param: :fields_sort,
      drop_param: :fields_drop
    )
  end
end
