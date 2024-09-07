# defmodule PlantAid.DiagnosticTests.FieldData do
#   use Ecto.Schema
#   import Ecto.Changeset
#   # alias PlantAid.DiagnosticTests.SelectOption

#   @primary_key false
#   embedded_schema do
#     # field :type, Ecto.Enum, values: [:string, :image, :select, :list, :map], default: :string
#     # field :subtype, Ecto.Enum, values: [:string, :image, :select]
#     field :value, :string

#     # embeds_many :select_options, SelectOption, on_replace: :delete

#     embeds_many :list_entries, ListEntry, on_replace: :delete do
#       field :value, :string
#     end

#     embeds_many :map_entries, MapEntry, on_replace: :delete do
#       field :key, :string
#       field :value, :string
#     end
#   end

#   def changeset(data, attrs) do
#     data
#     |> cast(attrs, [:value])
#     |> cast_embed(:list_entries, with: &list_entry_changeset/2)
#     |> cast_embed(:map_entries, with: &map_entry_changeset/2)
#     |> IO.inspect(label: "field data changeset")
#   end

#   defp list_entry_changeset(list_entries, attrs) do
#     list_entries
#     |> cast(attrs, [:value])
#   end

#   defp map_entry_changeset(map_entries, attrs) do
#     map_entries
#     |> cast(attrs, [:key, :value])
#   end
# end
