defmodule PlantAidWeb.MapLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Mapping

  @impl true
  def render(assigns) do
    ~H"""
    <div class="font-semibold text-3xl text-center p-4 text-lime-800">
      Plant Health Map
    </div>
    <div class="md:hidden text-center text-sm text-red-700 italic">
      <span class="text-red-700 font-semibold">Warning:</span>
      The Plant Health Map is not optimized for mobile devices. For optimal experience, try using a larger screen.
    </div>
    <div class="bg-lime-800 p-2 rounded-md">
      <div class="bg-lime-800 text-white font-semibold text-center pb-2">
        <%= @meta.total_count %> observations match filters
      </div>
      <div class="lg:flex lg:flex-row">
        <div class="basis-4/5">
          <div
            id="aggregate-map"
            phx-hook="MapBoxAggregateData"
            phx-update="ignore"
            style="height: calc(100vh - 200px);"
          >
          </div>
        </div>
        <div
          class=" mt-2 lg:mt-0 lg:ml-2 basis-1/5 bg-neutral-300 p-2 overflow-auto"
          style="height: calc(100vh - 200px);"
        >
          <.live_component
            module={PlantAidWeb.ObservationFilterForm}
            id="observation-filter-form"
            meta={@meta}
          />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:meta, %Flop.Meta{})
     |> assign(:page_title, "Home")}
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

        {:error, _meta} ->
          socket
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:updated_filters, params}, socket) do
    {:noreply, push_patch(socket, to: ~p"/map?#{params}")}
  end
end
