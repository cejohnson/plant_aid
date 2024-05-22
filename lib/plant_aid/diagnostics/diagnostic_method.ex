defmodule PlantAid.Diagnostics.DiagnosticMethod do
  use Ecto.Schema
  import Ecto.Changeset

  schema "diagnostic_methods" do
    field :name, :string
    field :description, :string

    embeds_many :fields, Field, on_replace: :delete do
      field :name, :string
      field :type, Ecto.Enum, values: [:string, :image, :select, :list, :map], default: :string
      field :data, :map
    end

    timestamps()
  end

  @doc false
  def changeset(diagnostic_method, attrs) do
    diagnostic_method
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> cast_embed(:fields,
      with: &field_changeset/2,
      sort_param: :field_order,
      drop_param: :field_delete
    )
  end

  defp field_changeset(field, attrs) do
    field
    |> cast(attrs, [:name, :type, :data])
    |> validate_required([:name])
  end
end
