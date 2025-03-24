defmodule PlantAidWeb.DiagnosticMethodLive.Form do
  use PlantAidWeb, :live_view

  alias PlantAid.DiagnosticMethods
  alias PlantAid.DiagnosticMethods.DiagnosticMethod

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @page_title %>
        <:subtitle>Use this form to manage diagnostic_method records in your database.</:subtitle>
      </.header>

      <.simple_form for={@form} id="diagnostic_method-form" phx-change="validate" phx-submit="save">
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
              <strong>map</strong>: a mapping of user provided string keys to string or select fields (ex: {"key": "value"}). You might want to use this if you know there will be labelled data, but you don't know what the labels will be ahead of time or they might change.
            </li>
          </ul>
          <div>
            If this diagnostic method allows testing for multiple pathologies, make sure to differentiate between fields that should be filled out once per test and fields that should be filled out once per pathology.
          </div>
        </div>

        <.inputs_for :let={f_field} field={@form[:fields]}>
          <div class="flex-col p-4 bg-neutral-100">
            <div class="flex space-x-2 items-top">
              <div class="pt-8">
                <button
                  class=""
                  type="button"
                  name="diagnostic_method[fields_drop][]"
                  value={f_field.index}
                  phx-click={JS.dispatch("change")}
                >
                  <.icon name="hero-trash" class="w-6 h-6 relative top-2" />
                </button>
              </div>
              <input type="hidden" name="diagnostic_method[fields_sort][]" value={f_field.index} />
              <.input field={f_field[:name]} type="text" label="Name" />
              <.input
                field={f_field[:per_pathology]}
                type="select"
                label="Fill Out"
                options={[{"Once Per Test", false}, {"For Each Pathology", true}]}
              />
              <.input
                field={f_field[:type]}
                type="select"
                label="Type"
                options={[:string, :image, :select, :list, :map]}
              />
              <%= case Ecto.Changeset.get_field(f_field.source, :type) do %>
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
                <% _ -> %>
              <% end %>

              <%= if Ecto.Changeset.get_field(f_field.source, :type) == :select or Ecto.Changeset.get_field(f_field.source, :subtype) == :select do %>
                <div class="">
                  <label class="text-sm font-semibold text-zinc-800">Options</label>
                  <.inputs_for :let={f_option} field={f_field[:select_options]}>
                    <input
                      type="hidden"
                      name={"diagnostic_method[fields][#{f_field.index}][select_options_sort][]"}
                      value={f_option.index}
                    />
                    <div class="flex items-end ">
                      <.input field={f_option[:value]} type="text" />
                      <label class="cursor-pointer pb-3">
                        <input
                          type="checkbox"
                          name={"diagnostic_method[fields][#{f_field.index}][select_options_drop][]"}
                          class="hidden"
                          value={f_option.index}
                        />
                        <.icon name="hero-x-mark" />
                      </label>
                    </div>
                  </.inputs_for>
                  <label class="cursor-pointer">
                    <input
                      type="checkbox"
                      name={"diagnostic_method[fields][#{f_field.index}][select_options_sort][]"}
                      class="hidden"
                    />
                    <div class="pt-4">
                      <.icon name="hero-plus-circle" />
                      <span class="align-middle">
                        Add Option
                      </span>
                    </div>
                  </label>
                </div>
              <% end %>
            </div>
            <div class="pl-8">
              <.input
                field={f_field[:description]}
                type="textarea"
                label="Description"
                description="This will appear as help text for this field when submitting test results, in exactly the same way as this help text is displayed here."
              />
            </div>
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

        <:actions>
          <.button variant="primary" phx-disable-with="Saving...">Save Diagnostic method</.button>
          <.button variant="secondary" type="button" phx-click="reset">Reset</.button>
          <.button type="button" phx-click="cancel">Cancel</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    pathology_options =
      PlantAid.Pathologies.list_pathologies() |> Enum.map(&{&1.common_name, &1.id})

    {:ok,
     socket
     |> assign(:pathology_options, pathology_options)
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_params(params, url, socket) do
    diagnostic_method = get_diagnostic_method(socket.assigns.live_action, params)

    changeset = DiagnosticMethods.change_diagnostic_method(diagnostic_method)

    {:noreply,
     socket
     |> assign(:url, url)
     |> assign(:diagnostic_method, diagnostic_method)
     |> assign_form(changeset)}
  end

  defp get_diagnostic_method(:edit, %{"id" => id}) do
    DiagnosticMethods.get_diagnostic_method!(id)
  end

  defp get_diagnostic_method(:new, _) do
    %DiagnosticMethod{}
  end

  @impl true
  def handle_event("validate", %{"diagnostic_method" => diagnostic_method_params}, socket) do
    changeset =
      socket.assigns.diagnostic_method
      |> DiagnosticMethods.change_diagnostic_method(diagnostic_method_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("reset", _, socket) do
    changeset = DiagnosticMethods.change_diagnostic_method(socket.assigns.diagnostic_method)

    {:noreply,
     socket
     |> assign_form(changeset)}
  end

  def handle_event("cancel", _, socket) do
    to =
      if String.contains?(socket.assigns.url, "show") do
        ~p"/admin/diagnostic_methods/#{socket.assigns.diagnostic_method}"
      else
        ~p"/admin/diagnostic_methods"
      end

    {:noreply,
     socket
     |> push_navigate(to: to)}
  end

  def handle_event("save", %{"diagnostic_method" => diagnostic_method_params}, socket) do
    save_diagnostic_method(socket, socket.assigns.live_action, diagnostic_method_params)
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
          {:noreply,
           socket
           |> put_flash(:info, "Diagnostic method updated successfully")
           |> push_navigate(to: ~p"/admin/diagnostic_methods/#{diagnostic_method}")}

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
          {:noreply,
           socket
           |> put_flash(:info, "Diagnostic method created successfully")
           |> push_navigate(to: ~p"/admin/diagnostic_methods/#{diagnostic_method}")}

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

  defp page_title(:new), do: "New Diagnostic Method"
  defp page_title(:edit), do: "Edit Diagnostic Method"
end
