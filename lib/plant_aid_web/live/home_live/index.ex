defmodule PlantAidWeb.HomeLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Mapping

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      This map shows suspected pathogen observations aggregated by secondary geographic subdivision (county, parish, district, municipality, etc.). These observations can be filtered using the accompanying form; for geographic filtering, first select a country, then primary subdivision, and finally a secondary subdivision.
    </div>
    <div><%= @meta.total_count %> observations match the current filter.</div>

    <div
      id="map"
      phx-hook="MapBox"
      phx-update="ignore"
      style="height: calc(100vh - 150px); max-height: calc(800px - 150px);"
    >
    </div>

    <.live_component
      module={PlantAidWeb.ObservationFilterForm}
      id="observation-filter-form"
      meta={@meta}
    />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:meta, %Flop.Meta{})}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      case Mapping.group_observations_by_secondary_subdivision(params) do
        {:ok, {data, meta}} ->
          {:noreply,
           push_event(
             socket
             |> assign(:meta, meta),
             "map-data",
             data
           )}

        {:error, meta} ->
          IO.inspect(meta.errors, label: "errors")
          socket
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:updated_filters, params}, socket) do
    {:noreply, push_patch(socket, to: ~p"/?#{params}")}
  end
end
