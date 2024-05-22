defmodule PlantAidWeb.DiagnosticMethodLive.FormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.Diagnostics

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage diagnostic_method records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="diagnostic_method-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <.label>Fields</.label>
        <.inputs_for :let={f_field} field={@form[:fields]}>
          <% IO.inspect(f_field, label: "f_field") %>
          <div class="flex space-x-2 items-center">
            <input type="hidden" name="diagnostic_method[field_order][]" value={f_field.index} />
            <.input field={f_field[:name]} type="text" placeholder="Name" />
            <.input
              field={f_field[:type]}
              type="select"
              placeholder="Type"
              options={[:string, :image, :select, :list, :map]}
            />
            <%= case Ecto.Changeset.get_field(f_field.source, :type) do %>
              <% :select -> %>
                <%= "select" %>
              <% _ -> %>
            <% end %>
            <label class="cursor-pointer">
              <input
                type="checkbox"
                name="diagnostic_method[field_delete][]"
                class="hidden"
                value={f_field.index}
              />
              <.icon name="hero-x-mark" />
            </label>
          </div>
        </.inputs_for>

        <label class="cursor-pointer">
          <input type="checkbox" name="diagnostic_method[field_order][]" class="hidden" />
          <.icon name="hero-plus-circle" /><span class="align-middle">Add Field</span>
        </label>

        <:actions>
          <.button phx-disable-with="Saving...">Save Diagnostic method</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{diagnostic_method: diagnostic_method} = assigns, socket) do
    changeset = Diagnostics.change_diagnostic_method(diagnostic_method)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"diagnostic_method" => diagnostic_method_params}, socket) do
    changeset =
      socket.assigns.diagnostic_method
      |> Diagnostics.change_diagnostic_method(diagnostic_method_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"diagnostic_method" => diagnostic_method_params}, socket) do
    save_diagnostic_method(socket, socket.assigns.action, diagnostic_method_params)
  end

  defp save_diagnostic_method(socket, :edit, diagnostic_method_params) do
    diagnostic_method = socket.assigns.diagnostic_method

    with :ok <-
           Bodyguard.permit(
             Diagnostics,
             :update_diagnostic_method,
             socket.assigns.user,
             diagnostic_method
           ) do
      case Diagnostics.update_diagnostic_method(
             diagnostic_method,
             diagnostic_method_params
           ) do
        {:ok, diagnostic_method} ->
          notify_parent({:saved, diagnostic_method})

          {:noreply,
           socket
           |> put_flash(:info, "Diagnostic method updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end

  defp save_diagnostic_method(socket, :new, diagnostic_method_params) do
    case Diagnostics.create_diagnostic_method(diagnostic_method_params) do
      {:ok, diagnostic_method} ->
        notify_parent({:saved, diagnostic_method})

        {:noreply,
         socket
         |> put_flash(:info, "Diagnostic method created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
