defmodule PlantAidWeb.PathologyLive.FormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.Pathologies

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage pathology records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="pathology-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :common_name}} type="text" label="common_name" />
        <.input field={{f, :scientific_name}} type="text" label="scientific_name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Pathology</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{pathology: pathology} = assigns, socket) do
    changeset = Pathologies.change_pathology(pathology)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"pathology" => pathology_params}, socket) do
    changeset =
      socket.assigns.pathology
      |> Pathologies.change_pathology(pathology_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"pathology" => pathology_params}, socket) do
    save_pathology(socket, socket.assigns.action, pathology_params)
  end

  defp save_pathology(socket, :edit, pathology_params) do
    case Pathologies.update_pathology(socket.assigns.pathology, pathology_params) do
      {:ok, _pathology} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pathology updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_pathology(socket, :new, pathology_params) do
    case Pathologies.create_pathology(pathology_params) do
      {:ok, _pathology} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pathology created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
