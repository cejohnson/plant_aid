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
        for={@form}
        id="pathology-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:common_name]} type="text" label="Common Name" />
        <.input field={@form[:scientific_name]} type="text" label="Scientific Name" />

        <div class="space-y-2">
          <.label>Genotypes</.label>
          <.inputs_for :let={f_genotype} field={@form[:genotypes]}>
            <div class="flex space-x-2 items-center">
              <input type="hidden" name="pathology[genotypes_order][]" value={f_genotype.index} />
              <.input field={f_genotype[:name]} type="text" placeholder="Name" />
              <label class="cursor-pointer">
                <input
                  type="checkbox"
                  name="pathology[genotypes_delete][]"
                  class="hidden"
                  value={f_genotype.index}
                />
                <.icon name="hero-x-mark" />
              </label>
            </div>
          </.inputs_for>
        </div>

        <label class="cursor-pointer">
          <input type="checkbox" name="pathology[genotypes_order][]" class="hidden" />
          <.icon name="hero-plus-circle" /><span class="align-middle">Add Genotype</span>
        </label>

        <:actions>
          <.button variant="primary" phx-disable-with="Saving...">Save Pathology</.button>
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
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"pathology" => pathology_params}, socket) do
    changeset =
      socket.assigns.pathology
      |> Pathologies.change_pathology(pathology_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign_form(changeset)}
  end

  def handle_event("save", %{"pathology" => pathology_params}, socket) do
    save_pathology(socket, socket.assigns.action, pathology_params)
  end

  defp save_pathology(socket, :edit, pathology_params) do
    current_user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Pathologies, :update_pathology, current_user) do
      case Pathologies.update_pathology(socket.assigns.pathology, pathology_params) do
        {:ok, pathology} ->
          notify_parent({:saved, pathology})

          {:noreply,
           socket
           |> put_flash(:info, "Pathology updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    end
  end

  defp save_pathology(socket, :new, pathology_params) do
    current_user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Pathologies, :create_pathology, current_user) do
      case Pathologies.create_pathology(pathology_params) do
        {:ok, pathology} ->
          notify_parent({:saved, pathology})

          {:noreply,
           socket
           |> put_flash(:info, "Pathology created successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
