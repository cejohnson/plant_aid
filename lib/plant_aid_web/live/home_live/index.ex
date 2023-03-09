defmodule PlantAidWeb.HomeLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.{
    Filters,
    Mapping
  }

  alias PlantAid.Observations.Observation

  @impl true
  def mount(_params, _session, socket) do
    host_options = Filters.list_host_options() |> format_options()
    location_type_options = Filters.list_location_type_options() |> format_options()
    pathology_options = Filters.list_pathology_options() |> format_options()
    country_options = Filters.list_country_options() |> format_options()

    {:ok,
     socket
     |> assign(:host_options, host_options)
     |> assign(:location_type_options, location_type_options)
     |> assign(:pathology_options, pathology_options)
     |> assign(:country_options, country_options)
     |> assign(:primary_subdivision_options, format_options())
     |> assign(:secondary_subdivision_options, format_options())
     |> assign(:meta, %Flop.Meta{})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket) do
      with {:ok, flop} <- Flop.validate(params, for: Observation) do
        current_flop = socket.assigns.meta.flop

        # If a higher level geographic entity changed we need to reset lower levels to avoid a situation like
        # country == "Canada" AND primary_subdivision == "North Carolina"
        flop = maybe_reset_geographic_filter_values(flop, current_flop)

        case Mapping.group_observations_by_secondary_subdivision(flop) do
          {map_data, bounding_box, meta} ->
            socket =
              socket
              |> assign(:meta, meta)
              |> maybe_assign_geographic_subdivision_options(flop, current_flop)

            {:noreply,
             push_event(
               socket,
               "map-data",
               %{bounding_box: bounding_box, data: map_data}
             )}

          error ->
            IO.inspect(error, label: "error")
            socket
        end
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update-filter", params, socket) do
    {:noreply, push_patch(socket, to: ~p"/?#{params}")}
  end

  @impl true
  def handle_event("reset-filter", params, %{assigns: assigns} = socket) do
    flop = assigns.meta.flop |> Flop.set_page(1) |> Flop.reset_filters()
    path = Flop.Phoenix.build_path(~p"/?#{params}", flop, backend: assigns.meta.backend)

    {:noreply,
     push_patch(
       socket,
       to: path
     )}
  end

  defp maybe_reset_geographic_filter_values(new_flop, old_flop) do
    cond do
      filter_changed?(:country_id, new_flop, old_flop) ->
        %{
          new_flop
          | filters:
              Flop.Filter.drop(new_flop.filters, [
                :primary_subdivision_id,
                :secondary_subdivision_id
              ])
        }

      filter_changed?(:primary_subdivision_id, new_flop, old_flop) ->
        %{new_flop | filters: Flop.Filter.drop(new_flop.filters, [:secondary_subdivision_id])}

      true ->
        new_flop
    end
  end

  defp maybe_assign_geographic_subdivision_options(socket, new_flop, old_flop) do
    cond do
      filter_changed?(:country_id, new_flop, old_flop) ->
        primary_subdivision_options =
          new_flop
          |> get_filter_value(:country_id)
          |> Filters.list_primary_subdivision_options()

        socket
        |> assign(:primary_subdivision_options, format_options(primary_subdivision_options))
        |> assign(:secondary_subdivision_options, format_options())

      filter_changed?(:primary_subdivision_id, new_flop, old_flop) ->
        secondary_subdivision_options =
          new_flop
          |> get_filter_value(:primary_subdivision)
          |> Filters.list_secondary_subdivision_options()

        socket
        |> assign(:secondary_subdivision_options, format_options(secondary_subdivision_options))

      true ->
        socket
    end
  end

  defp filter_changed?(field, flop1, flop2) do
    Flop.Filter.get(flop1.filters, field) != Flop.Filter.get(flop2.filters, field)
  end

  defp get_filter_value(flop, field) do
    filter = Flop.Filter.get(flop.filters, field)
    if filter, do: filter.value, else: nil
  end

  defp format_options(options \\ []) do
    [{"Any", nil} | options]
  end
end
