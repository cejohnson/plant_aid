defmodule PlantAidWeb.MapComponents do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :hook, :string, default: "MapBox"

  def mapbox_container(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook={@hook}
      phx-update="ignore"
      style="height: calc(100vh - 150px); max-height: calc(800px - 150px);"
    >
    </div>
    """
  end
end
