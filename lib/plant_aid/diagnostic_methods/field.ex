defmodule PlantAid.DiagnosticMethods.Field do
  use Ecto.Schema
  import Ecto.Changeset
  alias PlantAid.DiagnosticMethods.SelectOption

  embedded_schema do
    field :name, :string
    field :per_pathology, :boolean, default: false
    field :type, Ecto.Enum, values: [:string, :image, :select, :list, :map], default: :string
    field :subtype, Ecto.Enum, values: [:string, :image, :select]

    embeds_many :select_options, SelectOption, on_replace: :delete

    # embeds_one :data, FieldData, on_replace: :update
  end

  def changeset(field, attrs) do
    field
    |> cast(attrs, [:name, :per_pathology, :type, :subtype])
    |> validate_required([:name])
    |> cast_embed(:select_options,
      sort_param: :select_options_sort,
      drop_param: :select_options_drop
    )
    |> IO.inspect(label: "field_changeset")
  end
end
