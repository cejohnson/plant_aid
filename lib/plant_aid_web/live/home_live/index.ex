defmodule PlantAidWeb.HomeLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Mapping

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-xl p-2">
      Suspected Pathogen Observations
    </div>

    <div class="md:flex md:flex-row">
      <div class="basis-5/6">
        <div
          id="aggregate-map"
          phx-hook="MapBoxAggregateData"
          phx-update="ignore"
          style="height: calc(100vh - 200px);"
        >
        </div>
      </div>
      <div class="basis-1/6 bg-stone-300 p-2">
        <div><%= @meta.total_count %> observations match filters</div>

        <.live_component
          module={PlantAidWeb.ObservationFilterForm}
          id="observation-filter-form"
          meta={@meta}
        />
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
