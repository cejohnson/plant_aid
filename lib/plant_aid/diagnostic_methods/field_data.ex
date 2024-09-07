defmodule PlantAid.DiagnosticMethods.FieldData do
  use Ecto.Schema
  import Ecto.Changeset
  alias PlantAid.DiagnosticMethods.SelectOption

  @primary_key false
  embedded_schema do
    field :type, Ecto.Enum, values: [:string, :image, :select, :list, :map], default: :string
    field :subtype, Ecto.Enum, values: [:string, :image, :select]

    embeds_many :select_options, SelectOption, on_replace: :delete

    # embeds_one :list_data, ListData, on_replace: :update do
    #   field :type, Ecto.Enum, values: [:string, :image], default: :string
    # end

    # embeds_one :map_data, MapData, on_replace: :update do
    #   field :value_type, Ecto.Enum, values: [:string, :image, :select], default: :string
    #   embeds_many :select_options, SelectOption, on_replace: :delete
    # end
  end

  def changeset(data, attrs) do
    data
    |> cast(attrs, [:type, :subtype])
    |> cast_embed(:select_options,
      sort_param: :select_option_order,
      drop_param: :select_option_delete
    )

    # |> cast_embed(:list_data, with: &list_data_changeset/2)
    # |> cast_embed(:map_data, with: &map_data_changeset/2)
  end

  # defp list_data_changeset(list_data, attrs) do
  #   list_data
  #   |> cast(attrs, [:type])
  # end

  # defp map_data_changeset(map_data, attrs) do
  #   map_data
  #   |> cast(attrs, [:value_type])
  #   |> cast_embed(:select_options,
  #     sort_param: :select_option_order,
  #     drop_param: :select_option_delete
  #   )
  # end
end
