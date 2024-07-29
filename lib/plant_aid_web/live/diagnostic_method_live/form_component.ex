defmodule PlantAidWeb.DiagnosticMethodLive.FormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.DiagnosticMethods

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
        <.input
          field={@form[:pathology_ids]}
          type="select"
          multiple
          label="Tested Pathologies"
          options={@pathology_options}
        />

        <.header>Fields</.header>
        <div class="text-sm text-zinc-600">
          <div>
            This section allows you to add fields that should be filled out each time results are entered for a test using this diagnostic method. The following field types are supported:
          </div>
          <ul class="list-disc m-4">
            <li><strong>string</strong>: plain text</li>
            <li><strong>image</strong>: an image upload</li>
            <li><strong>select</strong>: a select dropdown with options you can provide here</li>
            <li><strong>list</strong>: a list of strings or images</li>
            <li>
              <strong>map</strong>: a mapping of user provided string keys to string or select fields (ex: {"key": "value"})
            </li>
          </ul>
          <div>
            If this diagnostic method allows testing for multiple pathologies, make sure to differentiate between fields that should be filled out once per test and fields that should be filled out once per pathology.
          </div>
        </div>

        <.inputs_for :let={f_field} field={@form[:fields]}>
          <div class="flex space-x-2 items-center">
            <input type="hidden" name="diagnostic_method[fields_sort][]" value={f_field.index} />
            <.input field={f_field[:name]} type="text" label="Name" />
            <.input
              field={f_field[:per_pathology]}
              type="select"
              label="Fill Out"
              options={[{"Once Per Test", false}, {"For Each Pathology", true}]}
            />
            <%!-- <.inputs_for :let={f_data} field={f_field[:data]}> --%>
            <.input
              field={f_field[:type]}
              type="select"
              label="Type"
              options={[:string, :image, :select, :list, :map]}
            />
            <%= case Ecto.Changeset.get_field(f_field.source, :type) do %>
              <%!-- <% :select -> %>
                <div>
                  <.inputs_for :let={f_option} field={f_field[:select_options]}>
                    <input
                      type="hidden"
                      name={"diagnostic_method[per_test_fields][#{f_field.index}][select_option_order][]"}
                      value={f_option.index}
                    />
                    <.input field={f_option[:value]} type="text" label="Option" />
                    <label class="cursor-pointer">
                      <input
                        type="checkbox"
                        name={"diagnostic_method[per_test_fields][#{f_field.index}][select_option_delete][]"}
                        class="hidden"
                        value={f_option.index}
                      />
                      <.icon name="hero-x-mark" />
                    </label>
                  </.inputs_for>
                  <label class="cursor-pointer">
                    <input
                      type="checkbox"
                      name={"diagnostic_method[per_test_fields][#{f_field.index}][select_option_order][]"}
                      class="hidden"
                    />
                    <.icon name="hero-plus-circle" /><span class="align-middle">Add Option</span>
                  </label>
                </div> --%>
              <% :list -> %>
                <.input
                  field={f_field[:subtype]}
                  type="select"
                  label="List Type"
                  options={[:string, :image]}
                />
              <% :map -> %>
                <.input
                  field={f_field[:subtype]}
                  type="select"
                  label="Map Type"
                  options={[:string, :select]}
                />
                <%!-- </.inputs_for> --%>
              <% _ -> %>
            <% end %>

            <%= if Ecto.Changeset.get_field(f_field.source, :type) == :select or Ecto.Changeset.get_field(f_field.source, :subtype) == :select do %>
              <div>
                <.inputs_for :let={f_option} field={f_field[:select_options]}>
                  <input
                    type="hidden"
                    name={"diagnostic_method[fields][#{f_field.index}][select_options_sort][]"}
                    value={f_option.index}
                  />
                  <.input field={f_option[:value]} type="text" label="Option" />
                  <label class="cursor-pointer">
                    <input
                      type="checkbox"
                      name={"diagnostic_method[fields][#{f_field.index}][select_options_drop][]"}
                      class="hidden"
                      value={f_option.index}
                    />
                    <.icon name="hero-x-mark" />
                  </label>
                </.inputs_for>
                <label class="cursor-pointer">
                  <input
                    type="checkbox"
                    name={"diagnostic_method[fields][#{f_field.index}][select_options_sort][]"}
                    class="hidden"
                  />
                  <.icon name="hero-plus-circle" /><span class="align-middle">Add Option</span>
                </label>
              </div>
            <% end %>
            <%!-- </.inputs_for> --%>

            <%!-- <label class="cursor-pointer">
              <input
                type="checkbox"
                name="diagnostic_method[per_test_field_delete][]"
                class="hidden"
                value={f_field.index}
              />
              <.icon name="hero-x-mark" />
            </label> --%>
            <button
              type="button"
              name="diagnostic_method[fields_drop][]"
              value={f_field.index}
              phx-click={JS.dispatch("change")}
            >
              <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
            </button>
          </div>
        </.inputs_for>

        <input type="hidden" name="diagnostic_method[fields_drop][]" />

        <button
          type="button"
          name="diagnostic_method[fields_sort][]"
          value="new"
          phx-click={JS.dispatch("change")}
        >
          <.icon name="hero-plus-circle" /><span class="align-middle">Add Field</span>
        </button>

        <%!-- <input type="hidden" name="mailing_list[emails_drop][]" />

        <label class="cursor-pointer">
          <input type="checkbox" name="diagnostic_method[per_test_field_order][]" class="hidden" />
          <.icon name="hero-plus-circle" /><span class="align-middle">Add Field</span>
        </label> --%>

        <:actions>
          <.button variant="primary" phx-disable-with="Saving...">Save Diagnostic method</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{diagnostic_method: diagnostic_method} = assigns, socket) do
    changeset = DiagnosticMethods.change_diagnostic_method(diagnostic_method)

    pathology_options =
      PlantAid.Pathologies.list_pathologies() |> Enum.map(fn p -> {p.common_name, p.id} end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:pathology_options, pathology_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"diagnostic_method" => diagnostic_method_params}, socket) do
    changeset =
      socket.assigns.diagnostic_method
      |> DiagnosticMethods.change_diagnostic_method(diagnostic_method_params)
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
             DiagnosticMethods,
             :update_diagnostic_method,
             socket.assigns.current_user,
             diagnostic_method
           ) do
      case DiagnosticMethods.update_diagnostic_method(
             socket.assigns.current_user,
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
    with :ok <-
           Bodyguard.permit(
             DiagnosticMethods,
             :create_diagnostic_method,
             socket.assigns.current_user
           ) do
      case DiagnosticMethods.create_diagnostic_method(
             socket.assigns.current_user,
             diagnostic_method_params
           ) do
        {:ok, diagnostic_method} ->
          notify_parent({:saved, diagnostic_method})

          {:noreply,
           socket
           |> put_flash(:info, "Diagnostic method created successfully")
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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
