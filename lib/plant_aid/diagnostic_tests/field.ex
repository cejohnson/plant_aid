defmodule PlantAid.DiagnosticTests.Field do
  use Ecto.Schema
  import Ecto.Changeset
  alias PlantAid.DiagnosticMethods.SelectOption

  embedded_schema do
    field :name, :string
    field :type, Ecto.Enum, values: [:string, :image, :select, :list, :map], default: :string
    field :subtype, Ecto.Enum, values: [:string, :image, :select, nil], default: nil
    field :value, :string
    field :delete, :boolean, virtual: true, default: false

    embeds_many :select_options, SelectOption, on_replace: :delete

    embeds_many :list_entries, ListEntry, on_replace: :delete do
      field :value, :string
      field :delete, :boolean, virtual: true, default: false
    end

    embeds_many :map_entries, MapEntry, on_replace: :delete do
      field :key, :string
      field :value, :string
    end
  end

  def changeset(field, attrs) do
    field
    |> cast(attrs, [:value, :delete])
    # |> cast_embed(:select_options)
    |> cast_embed(:list_entries,
      with: &list_entry_changeset/2,
      sort_param: :list_entries_sort,
      drop_param: :list_entries_drop
    )
    |> cast_embed(:map_entries,
      with: &map_entry_changeset/2,
      sort_param: :map_entries_sort,
      drop_param: :map_entries_drop
    )
  end

  defp list_entry_changeset(list_entries, attrs) do
    list_entries
    |> cast(attrs, [:value, :delete])
  end

  defp map_entry_changeset(map_entries, attrs) do
    map_entries
    |> cast(attrs, [:key, :value])
  end
end
