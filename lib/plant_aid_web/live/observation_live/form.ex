defmodule PlantAidWeb.ObservationLive.Form do
  use PlantAidWeb, :live_view

  alias PlantAid.ObjectStorage
  alias PlantAid.Observations
  alias PlantAid.Observations.Observation
  # alias PlantAid.Diagnostics.{LAMPDetails, VOCDetails}

  alias PlantAid.FormHelpers

  @impl true
  def mount(_params, _session, socket) do
    host_options = FormHelpers.list_host_options() |> prepend_default_option()

    location_type_options = FormHelpers.list_location_type_options() |> prepend_default_option()
    pathology_options = FormHelpers.list_pathology_options() |> prepend_default_option()
    country_options = FormHelpers.list_country_options() |> prepend_default_option()

    # primary_subdivision_options = [{"First select country", nil}]
    # secondary_subdivision_options = [{"First select primary subdivision", nil}]

    {:ok,
     socket
     |> assign(:host_options, host_options)
     |> assign(:location_type_options, location_type_options)
     |> assign(:pathology_options, pathology_options)
     |> assign(:country_options, country_options)
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 10,
       external: &presign_upload/2
     )}

    #  |> allow_upload(:lamp_initial_image,
    #    accept: ~w(.jpg .jpeg .png),
    #    max_entries: 10,
    #    external: &presign_upload/2
    #  )
    #  |> allow_upload(:lamp_final_image,
    #    accept: ~w(.jpg .jpeg .png),
    #    max_entries: 10,
    #    external: &presign_upload/2
    #  )
    #  |> allow_upload(:voc_result_image,
    #    accept: ~w(.jpg .jpeg .png),
    #    max_entries: 10,
    #    external: &presign_upload/2
    #  )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign_observation(socket.assigns.live_action, params)
     |> assign_from_observation()
     |> assign(:page_title, page_title(socket.assigns.live_action))}

    #  |> assign_remaining}
  end

  defp assign_observation(socket, :edit, %{"id" => id}) do
    observation = Observations.get_observation!(id)

    socket
    |> assign(:observation, observation)
  end

  defp assign_observation(socket, :new, _) do
    socket
    |> assign(:observation, %Observation{
      # user: socket.assigns.current_user
      # lamp_details: nil,
      # voc_details: nil
    })
  end

  defp assign_from_observation(socket) do
    observation = socket.assigns.observation
    changeset = Observations.change_observation(observation)

    host_variety_options = FormHelpers.list_host_variety_options(observation.host_id)

    primary_subdivision_options =
      FormHelpers.list_primary_subdivision_options(observation.country_id)
      |> prepend_default_option()

    secondary_subdivision_options =
      FormHelpers.list_secondary_subdivision_options(observation.primary_subdivision_id)
      |> prepend_default_option()

    socket
    |> assign_form(changeset)
    |> assign(:primary_subdivision_options, primary_subdivision_options)
    |> assign(:secondary_subdivision_options, secondary_subdivision_options)
    |> assign(:host_variety_options, host_variety_options)
    |> assign(:selected_country_id, observation.country_id)
    |> assign(:selected_primary_subdivision_id, observation.primary_subdivision_id)
    |> assign(:selected_host, observation.host_id)
  end

  @impl true
  def handle_event("validate", %{"observation" => observation_params}, socket) do
    changeset =
      socket.assigns.observation
      |> Observations.change_observation(observation_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> maybe_assign_geographic_subdivision_options(changeset)
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"observation" => observation_params}, socket) do
    save_observation(socket, socket.assigns.live_action, observation_params)
  end

  def handle_event(
        "set_position",
        %{"latitude" => latitude, "longitude" => longitude},
        socket
      ) do
    changeset =
      socket.assigns.form.source
      |> Observation.put_coordinates(latitude, longitude)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign_form(changeset)}
  end

  def handle_event("on_current_position_error", %{"message" => message}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, message)}
  end

  def handle_event("set_geography", _, socket) do
    changeset =
      socket.assigns.form.source
      |> Observation.maybe_put_geography_from_position()
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> maybe_assign_geographic_subdivision_options(changeset)
     |> assign_form(changeset)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  defp save_observation(socket, :edit, observation_params) do
    observation_params = put_upload_urls(observation_params, socket)

    case Observations.update_observation(
           socket.assigns.observation,
           observation_params,
           &consume_images(socket, &1)
         ) do
      {:ok, observation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Observation updated successfully")
         |> push_navigate(to: ~p"/observations/#{observation}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_observation(socket, :new, observation_params) do
    observation_params = put_upload_urls(observation_params, socket)

    case Observations.create_observation(
           socket.assigns.current_user,
           observation_params,
           &consume_images(socket, &1)
         ) do
      {:ok, observation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Observation created successfully")
         |> push_navigate(to: ~p"/observations/#{observation}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp maybe_assign_geographic_subdivision_options(
         socket,
         %Ecto.Changeset{
           changes: %{country_id: country_id, primary_subdivision_id: primary_subdivision_id}
         }
       )
       when socket.assigns.selected_country_id != country_id and
              socket.assigns.selected_primary_subdivision_id != primary_subdivision_id do
    primary_subdivision_options =
      FormHelpers.list_primary_subdivision_options(country_id) |> prepend_default_option()

    secondary_subdivision_options =
      FormHelpers.list_secondary_subdivision_options(primary_subdivision_id)
      |> prepend_default_option()

    socket
    |> assign(:selected_country_id, country_id)
    |> assign(:selected_primary_subdivision_id, primary_subdivision_id)
    |> assign(:primary_subdivision_options, primary_subdivision_options)
    |> assign(:secondary_subdivision_options, secondary_subdivision_options)
  end

  defp maybe_assign_geographic_subdivision_options(
         socket,
         %Ecto.Changeset{changes: %{country_id: country_id}}
       )
       when socket.assigns.selected_country_id != country_id do
    primary_subdivision_options =
      FormHelpers.list_primary_subdivision_options(country_id) |> prepend_default_option()

    secondary_subdivision_options = prepend_default_option()

    socket
    |> assign(:selected_country_id, country_id)
    |> assign(:primary_subdivision_options, primary_subdivision_options)
    |> assign(:secondary_subdivision_options, secondary_subdivision_options)
  end

  defp maybe_assign_geographic_subdivision_options(
         socket,
         %Ecto.Changeset{changes: %{primary_subdivision_id: primary_subdivision_id}}
       )
       when socket.assigns.selected_primary_subdivision_id != primary_subdivision_id do
    secondary_subdivision_options =
      FormHelpers.list_secondary_subdivision_options(primary_subdivision_id)
      |> prepend_default_option()

    socket
    |> assign(:selected_primary_subdivision_id, primary_subdivision_id)
    |> assign(:secondary_subdivision_options, secondary_subdivision_options)
  end

  defp maybe_assign_geographic_subdivision_options(socket, _) do
    socket
  end

  # def handle_event(
  #       "current_position",
  #       %{"latitude" => latitude, "longitude" => longitude},
  #       socket
  #     ) do
  #   changeset =
  #     socket.assigns.changeset
  #     |> Ecto.Changeset.put_change(:latitude, latitude)
  #     |> Ecto.Changeset.put_change(:longitude, longitude)

  #   {:noreply, assign(socket, :changeset, changeset)}
  # end

  # def handle_event("current_position_error", %{"message" => message}, socket) do
  #   {:noreply,
  #    put_flash(
  #      socket,
  #      :error,
  #      "Error getting current position: '#{message}'. Refreshing may fix this."
  #    )}
  # end

  # defp save_observation(socket, :edit, observation_params) do
  #   observation_params = put_upload_urls(observation_params, socket)

  #   case Observations.update_observation(
  #          socket.assigns.observation,
  #          observation_params,
  #          &consume_images(socket, &1)
  #        ) do
  #     {:ok, observation} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Observation updated successfully")
  #        |> push_redirect(to: Routes.observation_show_path(socket, :show, observation))}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, :changeset, changeset)}
  #   end
  # end

  # defp save_observation(socket, :new, observation_params) do
  #   observation_params = put_upload_urls(observation_params, socket)

  #   case Observations.create_observation(
  #          socket.assigns.observation,
  #          observation_params,
  #          &consume_images(socket, &1)
  #        ) do
  #     {:ok, observation} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Observation created successfully")
  #        |> push_redirect(to: Routes.observation_show_path(socket, :show, observation))}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, changeset: changeset)}
  #   end
  # end

  # defp get_selected_host(changeset, hosts) do
  #   with host_id <- Ecto.Changeset.get_field(changeset, :host_id) do
  #     Enum.find(hosts, fn h -> h.id == host_id end) || List.first(hosts)
  #   end
  # end

  # defp research_plot?(changeset, location_types) do
  #   with location_type_id <- Ecto.Changeset.get_field(changeset, :location_type_id) do
  #     location_type =
  #       Enum.find(location_types, fn lt -> lt.id == location_type_id end) ||
  #         List.first(location_types)

  #     location_type && location_type.name == "Research plot"
  #   end
  # end

  # defp page_title(:new), do: "Create Observation"
  # defp page_title(:edit), do: "Edit Observation"

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"

  defp put_upload_urls(%{} = observation_params, socket) do
    observation_params
    |> put_image_urls(socket)

    # |> put_lamp_details(socket)
    # |> put_voc_details(socket)
  end

  defp put_image_urls(observation_params, socket) do
    new_urls = get_upload_urls(socket, :image)

    if length(new_urls) > 0 do
      Map.put(
        observation_params,
        "image_urls",
        Enum.concat(socket.assigns.observation.image_urls, new_urls)
      )
    else
      observation_params
    end
  end

  # defp put_lamp_details(%{} = observation_params, socket) do
  #   new_initial_image_urls = get_upload_urls(socket, :lamp_initial_image)
  #   new_final_image_urls = get_upload_urls(socket, :lamp_final_image)

  #   if length(new_initial_image_urls) > 0 or length(new_final_image_urls) > 0 do
  #     lamp_details = socket.assigns.observation.lamp_details || %LAMPDetails{}

  #     lamp_details_params = %{
  #       "id" => lamp_details.id,
  #       "initial_image_urls" =>
  #         Enum.concat(lamp_details.initial_image_urls, new_initial_image_urls),
  #       "final_image_urls" => Enum.concat(lamp_details.final_image_urls, new_final_image_urls)
  #     }

  #     Map.put(observation_params, "lamp_details", lamp_details_params)
  #   else
  #     observation_params
  #   end
  # end

  # defp put_voc_details(%{} = observation_params, socket) do
  #   new_result_image_urls = get_upload_urls(socket, :voc_result_image)

  #   if length(new_result_image_urls) > 0 do
  #     voc_details = socket.assigns.observation.voc_details || %VOCDetails{}

  #     voc_details_params = %{
  #       "id" => voc_details.id,
  #       "result_image_urls" => Enum.concat(voc_details.result_image_urls, new_result_image_urls)
  #     }

  #     Map.put(observation_params, "voc_details", voc_details_params)
  #   else
  #     observation_params
  #   end
  # end

  defp get_upload_urls(socket, upload_key) do
    {completed, []} = uploaded_entries(socket, upload_key)

    for entry <- completed do
      entry
      |> object_storage_key()
      |> ObjectStorage.get_url()
    end
  end

  defp consume_images(socket, %Observation{} = observation) do
    consume_uploaded_entries(socket, :image, fn _meta, _entry -> {:ok, nil} end)
    {:ok, observation}
  end

  defp presign_upload(entry, socket) do
    meta =
      ObjectStorage.get_upload_meta(
        key: object_storage_key(entry),
        content_type: entry.client_type,
        max_file_size: socket.assigns.uploads[entry.upload_config].max_file_size,
        expires_in: :timer.hours(24)
      )

    {:ok, meta, socket}
  end

  defp object_storage_key(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "images/#{entry.uuid}.#{ext}"
  end

  defp prepend_default_option(options \\ []) do
    [{"Select", nil}] ++ options
  end

  defp page_title(:new), do: "Create Observation"
  defp page_title(:edit), do: "Edit Observation"
end
