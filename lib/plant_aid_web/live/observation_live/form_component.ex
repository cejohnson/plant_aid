defmodule PlantAidWeb.ObservationLive.FormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.Observations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage observation records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="observation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :observation_date}} type="datetime-local" label="observation_date" />
        <.input field={{f, :position}} type="text" label="position" />
        <.input field={{f, :organic}} type="checkbox" label="organic" />
        <.input field={{f, :control_method}} type="text" label="control_method" />
        <.input field={{f, :host_other}} type="text" label="host_other" />
        <.input field={{f, :notes}} type="text" label="notes" />
        <.input field={{f, :metadata}} type="text" label="metadata" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Observation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{observation: observation} = assigns, socket) do
    changeset = Observations.change_observation(observation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"observation" => observation_params}, socket) do
    changeset =
      socket.assigns.observation
      |> Observations.change_observation(observation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"observation" => observation_params}, socket) do
    save_observation(socket, socket.assigns.action, observation_params)
  end

  defp save_observation(socket, :edit, observation_params) do
    case Observations.update_observation(socket.assigns.observation, observation_params) do
      {:ok, _observation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Observation updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_observation(socket, :new, observation_params) do
    case Observations.create_observation(observation_params) do
      {:ok, _observation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Observation created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
