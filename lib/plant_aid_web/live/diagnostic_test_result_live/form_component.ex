defmodule PlantAidWeb.DiagnosticTestResultLive.FormComponent do
  alias PlantAid.DiagnosticTests.PathologyResult
  use PlantAidWeb, :live_component

  alias Ecto.Changeset
  alias PlantAid.DiagnosticMethods
  alias PlantAid.DiagnosticTests
  alias PlantAid.ObjectStorage
  alias PlantAid.DiagnosticTests.Field
  alias PlantAid.DiagnosticTests.FieldData
  alias PlantAid.DiagnosticTests.PathologyResult
  alias PlantAid.DiagnosticTests.SelectOption
  alias PlantAid.DiagnosticTests.TestResult

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage test_result records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="test_result-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:observation_id]} type="text" label="Observation ID" />
        <.input field={@form[:comments]} type="textarea" label="Comments" />
        <.input
          field={@form[:diagnostic_method_id]}
          type="select"
          label="Diagnostic Method"
          prompt="Select"
          options={@diagnostic_method_options}
          phx-change="change-diagnostic-method"
        />

        <%= if Changeset.get_field(@form.source, :diagnostic_method_id) do %>
          <.label>Fields</.label>
          <.inputs_for :let={f_field} field={@form[:fields]}>
            <%!-- <input type="hidden" name="test_result[field_order][]" value={f_field.index} /> --%>
            <%!-- <.inputs_for :let={f_field_data} field={f_field[:data]}> --%>
            <%!-- <% IO.inspect(f_field.data, label: "f_field.data") %> --%>
            <%!-- <.input field={f_field[:value]} type="text" label={f_field.data.name} /> --%>
            <%!-- <.label><%= f_field.data.descriptor.name %></.label> --%>
            <%!-- <% IO.inspect(f_field, label: "f_field wtf") %> --%>
            <%!-- <input type="hidden" name="test_result[field_order][]" value={f_field.index} /> --%>
            <%= case f_field.data.type do %>
              <% :string -> %>
                <.input field={f_field[:value]} type="text" label={f_field.data.name} />
              <% :image -> %>
                <.label><%= f_field.data.name %></.label>
                <%= if f_field.data.value do %>
                  <.label>Current Image</.label>
                  <img src={f_field.data.value} height="200" width="200" />
                <% end %>
                <.live_file_input upload={@uploads[f_field.data.name]} />
                <section class="pt-2" phx-drop-target={@uploads[f_field.data.name].ref}>
                  <%= for entry <- @uploads[f_field.data.name].entries do %>
                    <article>
                      <figure>
                        <.live_img_preview entry={entry} width={200} />
                        <figcaption><%= entry.client_name %></figcaption>
                      </figure>

                      <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

                      <.button
                        type="button"
                        class="bg-stone-500"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        aria-label="cancel"
                      >
                        &times;
                      </.button>

                      <%= for err <- upload_errors(@uploads[f_field.data.name], entry) do %>
                        <p><%= error_to_string(err) %></p>
                      <% end %>
                    </article>
                  <% end %>

                  <%= for err <- upload_errors(@uploads[f_field.data.name]) do %>
                    <p><%= error_to_string(err) %></p>
                  <% end %>
                </section>
              <% :select -> %>
                <.input
                  field={f_field[:value]}
                  type="select"
                  label={f_field.data.name}
                  prompt="Select"
                  options={Enum.map(f_field.data.select_options, & &1.value)}
                />
              <% :list -> %>
                <.label><%= f_field.data.name %></.label>
                <%= case f_field.data.subtype do %>
                  <% :string -> %>
                    <.inputs_for :let={f_entry} field={f_field[:list_entries]}>
                      <input
                        type="hidden"
                        name={"test_result[fields][#{f_field.index}][list_entries_sort][]"}
                        value={f_entry.index}
                      />
                      <.input field={f_entry[:value]} type="text" />
                      <button
                        type="button"
                        name={"test_result[fields][#{f_field.index}][list_entries_drop][]"}
                        value={f_entry.index}
                        phx-click={JS.dispatch("change")}
                      >
                        <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
                      </button>
                    </.inputs_for>

                    <input
                      type="hidden"
                      name={"test_result[fields][#{f_field.index}][list_entries_drop][]"}
                    />

                    <button
                      type="button"
                      name={"test_result[fields][#{f_field.index}][list_entries_sort][]"}
                      value="new"
                      phx-click={JS.dispatch("change")}
                    >
                      <.icon name="hero-plus-circle" /><span class="align-middle">Add Entry</span>
                    </button>
                  <% :image -> %>
                    <%= if length(f_field.data.list_entries) > 0 do %>
                      <.label>Current Images</.label>
                      <%= for entry <- f_field.data.list_entries do %>
                        <img src={entry.value} height="200" width="200" />
                      <% end %>
                    <% end %>
                    <.live_file_input upload={@uploads[f_field.data.name]} />
                    <section class="pt-2" phx-drop-target={@uploads[f_field.data.name].ref}>
                      <%= for entry <- @uploads[f_field.data.name].entries do %>
                        <article>
                          <figure>
                            <.live_img_preview entry={entry} width={200} />
                            <figcaption><%= entry.client_name %></figcaption>
                          </figure>

                          <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

                          <.button
                            type="button"
                            class="bg-stone-500"
                            phx-click="cancel-upload"
                            phx-value-ref={entry.ref}
                            aria-label="cancel"
                          >
                            &times;
                          </.button>

                          <%= for err <- upload_errors(@uploads[f_field.data.name], entry) do %>
                            <p><%= error_to_string(err) %></p>
                          <% end %>
                        </article>
                      <% end %>

                      <%= for err <- upload_errors(@uploads[f_field.data.name]) do %>
                        <p><%= error_to_string(err) %></p>
                      <% end %>
                    </section>
                <% end %>
              <% :map -> %>
                <.label><%= f_field.data.name %></.label>
                <.inputs_for :let={f_entry} field={f_field[:map_entries]}>
                  <input
                    type="hidden"
                    name={"test_result[fields][#{f_field.index}][map_entries_sort][]"}
                    value={f_entry.index}
                  />
                  <.input field={f_entry[:key]} type="text" label="Key" />
                  <%= case f_field.data.subtype do %>
                    <% :string -> %>
                      <.input field={f_entry[:value]} type="text" label="Value" />
                    <% :select -> %>
                      <.input
                        field={f_entry[:value]}
                        type="select"
                        label="Value"
                        prompt="Select"
                        options={Enum.map(f_field.data.select_options, & &1.value)}
                      />
                  <% end %>
                  <button
                    type="button"
                    name={"test_result[fields][#{f_field.index}][map_entries_drop][]"}
                    value={f_entry.index}
                    phx-click={JS.dispatch("change")}
                  >
                    <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
                  </button>
                </.inputs_for>

                <input
                  type="hidden"
                  name={"test_result[fields][#{f_field.index}][map_entries_drop][]"}
                />

                <button
                  type="button"
                  name={"test_result[fields][#{f_field.index}][map_entries_sort][]"}
                  value="new"
                  phx-click={JS.dispatch("change")}
                >
                  <.icon name="hero-plus-circle" /><span class="align-middle">Add Entry</span>
                </button>
            <% end %>
            <%!-- </.inputs_for> --%>
            <%!-- <input type="hidden" name="test_result[field_order][]" value={f_field.index} />
            <label class="cursor-pointer">
              <input
                type="checkbox"
                name="test_result[field_delete][]"
                class="hidden"
                value={f_field.index}
              />
              <.icon name="hero-x-mark" />
            </label> --%>
          </.inputs_for>
          <%!-- <label class="cursor-pointer">
            <input type="checkbox" name="test_result[field_order][]" class="hidden" />
            <.icon name="hero-plus-circle" /><span class="align-middle">Add Field</span>
          </label> --%>
        <% end %>

        <:actions>
          <.button phx-disable-with="Saving...">Save Diagnostic test result</.button>
          <.button phx-click="reset">Reset</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{test_result: test_result} = assigns, socket) do
    changeset = DiagnosticTests.change_test_result(test_result)

    diagnostic_method_options =
      DiagnosticMethods.list_diagnostic_methods() |> Enum.map(&{&1.name, &1.id})

    # diagnostic_methods_to_changesets =
    #   case test_result.diagnostic_method_id do
    #     nil ->
    #       %{}

    #     id ->
    #       Map.new()
    #       |> Map.put(Integer.to_string(id), changeset)
    #   end

    socket =
      test_result.fields
      |> Enum.filter(fn field ->
        field.type == :image or field.subtype == :image
      end)
      |> Enum.reduce(socket, fn field, socket ->
        case field.type do
          :image ->
            allow_upload(socket, field.name,
              accept: ~w(.jpg .jpeg .png),
              max_entries: 1,
              external: &presign_upload/2
            )

          :list ->
            allow_upload(socket, field.name,
              accept: ~w(.jpg .jpeg .png),
              max_entries: 20,
              external: &presign_upload/2
            )
        end
      end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:diagnostic_method_options, diagnostic_method_options)
     #  |> assign(:diagnostic_methods_to_changesets, diagnostic_methods_to_changesets)
     |> assign(:original_test_result, test_result)
     #  |> assign(:diagnostic_method_changeset, changeset)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"test_result" => test_result_params}, socket) do
    IO.inspect(test_result_params, label: "test_result_params")
    # IO.inspect(List.first(socket.assigns.form.source.changes.fields).data, label: "form data")
    # test_result_or_changeset =
    #   case Map.get(test_result_params, "diagnostic_method_id") do
    #     nil ->
    #       socket.assigns.test_result

    #     id ->
    #       Map.get(socket.assigns.diagnostic_methods_to_changesets, id)
    #   end

    # IO.inspect(Ecto.Changeset.get_field(socket.assigns.test_result, :fields), label: "fields")

    # attrs =
    #   DiagnosticTests.merge_diagnostic_method_attrs(
    #     test_result_params,
    #     socket.assigns.diagnostic_method_attrs
    #   )

    # changeset = socket.assigns.form.source
    # |> DiagnosticTests.change_test_result(test_result_params)
    # |> Map.put(:action, :validate)

    changeset =
      socket.assigns.test_result
      # |> DiagnosticTests.change_test_result(socket.assigns.form.source)
      # |> IO.inspect(label: "test_result")
      |> DiagnosticTests.change_test_result(test_result_params)
      # |> Ecto.Changeset.merge(socket.assigns.diagnostic_method_changeset)
      |> IO.inspect(label: "changeset")
      |> Map.put(:action, :validate)

    # diagnostic_methods_to_changesets =
    #   case test_result_params["diagnostic_method_id"] do
    #     nil ->
    #       socket.assigns.diagnostic_methods_to_changesets

    #     id ->
    #       Map.put(socket.assigns.diagnostic_methods_to_changesets, id, changeset)
    #   end

    # socket = test_result_params["fields"]
    # |> Enum.

    {:noreply,
     socket
     #  |> assign(:diagnostic_methods_to_changesets, diagnostic_methods_to_changesets)
     |> assign_form(changeset)}
  end

  def handle_event("reset", _, socket) do
    changeset = DiagnosticTests.change_test_result(socket.assigns.original_test_result)

    {:noreply,
     socket |> assign(:test_result, socket.assigns.original_test_result) |> assign_form(changeset)}
  end

  def handle_event(
        "change-diagnostic-method",
        %{"test_result" => %{"diagnostic_method_id" => diagnostic_method_id}},
        socket
      ) do
    IO.inspect(diagnostic_method_id, label: "diagnostic_method_id")
    IO.inspect(socket.assigns.form.params, label: "params")

    # test_result =
    #   %TestResult{fields: fields, pathology_results: pathology_results}
    #   |> IO.inspect(label: "test_result!")

    # diagnostic_method_attrs =
    #   DiagnosticTests.get_diagnostic_method_attrs(diagnostic_method_id)
    #   |> IO.inspect(label: "dm attrs")

    # attrs =
    #   DiagnosticTests.merge_diagnostic_method_attrs(
    #     socket.assigns.form.params,
    #     diagnostic_method_attrs
    #   )
    #   |> IO.inspect(label: "attrs")

    test_result =
      DiagnosticTests.change_diagnostic_method(socket.assigns.test_result, diagnostic_method_id)

    # {changeset, fields} =
    #   DiagnosticTests.change_diagnostic_method(socket.assigns.test_result, diagnostic_method_id)

    # test_result =
    #   DiagnosticTests.change_diagnostic_method(
    #     socket.assigns.original_test_result,
    #     socket.assigns.form.params,
    #     diagnostic_method_id
    #   )
    #   |> IO.inspect(label: "new test result")

    # IO.inspect(Ecto.Changeset.get_field(changeset, :fields), label: "fields")

    changeset =
      test_result
      |> DiagnosticTests.change_test_result(
        Map.put(socket.assigns.form.params, "diagnostic_method_id", diagnostic_method_id)
      )

    # |> DiagnosticTests.change_diagnostic_method(diagnostic_method_id)

    # changeset = Ecto.Changeset.merge(diagnostic_method_changeset, changeset)

    # socket.assigns.form.params
    # |> Ecto.Changeset.put_change(:diagnostic_method_id, id)
    # |> Ecto.Changeset.put_embed(:fields, fields)
    # |> Ecto.Changeset.put_assoc(:pathology_results, pathology_results)

    # current_changeset = socket.assigns.form.source
    # diagnostic_method_id = Ecto.Changeset.get_field(current_changeset, :diagnostic_method_id)

    # diagnostic_methods_to_changesets =
    #   Map.put(
    #     socket.assigns.diagnostic_methods_to_changesets,
    #     diagnostic_method_id,
    #     current_changeset
    #   )

    # new_changeset =
    #   case Map.get(socket.assigns.diagnostic_methods_to_changesets, id) do
    #     nil ->
    #       diagnostic_method = DiagnosticMethods.get_diagnostic_method!(id)

    #       # TODO: checkpoint current form in case we need to revert? Maybe in a map?
    #       fields =
    #         diagnostic_method.per_test_fields
    #         |> Enum.map(fn field ->
    #           %Field{descriptor: field}
    #         end)

    #       # TODO: is this going to bite me?
    #       per_pathology_fields =
    #         Enum.map(diagnostic_method.per_pathology_fields, fn field ->
    #           %Field{descriptor: field}
    #         end)

    #       pathology_results =
    #         Enum.map(diagnostic_method.pathologies, fn pathology ->
    #           %PathologyResult{pathology: pathology, fields: per_pathology_fields}
    #         end)

    #       # test_result =
    #       #   %TestResult{fields: fields, pathology_results: pathology_results}
    #       #   |> IO.inspect(label: "test_result!")

    #       socket.assigns.form.source
    #       |> Ecto.Changeset.put_change(:diagnostic_method_id, id)
    #       |> Ecto.Changeset.put_embed(:fields, fields)
    #       |> Ecto.Changeset.put_assoc(:pathology_results, pathology_results)

    #     # DiagnosticTests.change_test_result(test_result)

    #     changeset ->
    #       changeset
    #   end
    #   |> IO.inspect(label: "changeset!")

    # case Map.get(socket.assigns.diagnostic_methods_to_changesets, )

    # socket.assigns.form.source
    # |> Changeset.put_embed(:fields, fields)

    # TODO: clear uploads when changing methods
    # socket =
    #   Enum.reduce(socket.assigns.uploads, socket, fn upload, socket ->
    #     disallow_upload(socket, upload)
    #   end)

    socket =
      test_result.fields
      |> Enum.filter(fn field ->
        field.type == :image or field.subtype == :image
      end)
      |> Enum.reduce(socket, fn field, socket ->
        max_entries = if field.type == :image, do: 1, else: 20

        allow_upload(socket, field.name,
          accept: ~w(.jpg .jpeg .png),
          max_entries: max_entries,
          external: &presign_upload/2
        )
      end)

    {:noreply,
     socket
     |> assign(:test_result, test_result)
     |> assign_form(changeset)}
  end

  def handle_event("cancel-upload", %{"ref" => ref} = payload, socket) do
    IO.inspect(payload, label: "payload")
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("save", %{"test_result" => test_result_params}, socket) do
    test_result_params =
      put_upload_urls(socket.assigns.test_result, test_result_params, socket)
      |> IO.inspect(label: "params with urls")

    save_test_result(socket, socket.assigns.action, test_result_params)
  end

  defp save_test_result(socket, :edit, test_result_params) do
    with :ok <-
           Bodyguard.permit(
             DiagnosticTests,
             :update_test_result,
             socket.assigns.current_user,
             socket.assigns.test_result
           ) do
      case DiagnosticTests.update_test_result(
             socket.assigns.current_user,
             socket.assigns.test_result,
             test_result_params,
             &consume_images(socket, &1)
           ) do
        {:ok, test_result} ->
          notify_parent({:saved, test_result})

          {:noreply,
           socket
           |> put_flash(:info, "Test result updated successfully")
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

  defp save_test_result(socket, :new, test_result_params) do
    with :ok <-
           Bodyguard.permit(
             DiagnosticTests,
             :create_test_result,
             socket.assigns.current_user
           ) do
      case DiagnosticTests.create_test_result(
             socket.assigns.current_user,
             socket.assigns.test_result,
             test_result_params,
             &consume_images(socket, &1)
           ) do
        {:ok, test_result} ->
          notify_parent({:saved, test_result})

          {:noreply,
           socket
           |> put_flash(:info, "Test result created successfully")
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
    assign(socket, :form, to_form(changeset) |> IO.inspect(label: "form"))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

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

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"

  def put_upload_urls(%TestResult{} = test_result, test_result_params, socket) do
    test_result.fields
    |> Enum.filter(fn field ->
      field.type == :image or field.subtype == :image
    end)
    |> Enum.reduce(test_result_params, fn field, test_result_params ->
      new_urls =
        get_upload_urls(socket, field.name)
        |> IO.inspect(label: "new_urls")

      if length(new_urls) > 0 do
        IO.inspect(field.id, label: "field id")
        IO.inspect(test_result_params, label: "test_result_params")

        persistent_id =
          Enum.find_value(
            test_result_params["fields"] |> IO.inspect(label: "field params"),
            fn {persistent_id, field_params} ->
              IO.inspect(field_params, label: "field params")
              if field.id == field_params["id"], do: persistent_id
            end
          )

        # TODO: we need to delete old images here
        case field.type do
          :image ->
            put_in(
              test_result_params,
              ["fields", persistent_id, "value"],
              List.first(new_urls)
            )

          :list ->
            list_entries =
              new_urls
              |> Enum.map(fn url ->
                %{"value" => url}
              end)

            list_entries =
              field.list_entries
              |> Enum.map(&Map.from_struct/1)
              |> Enum.concat(list_entries)

            put_in(
              test_result_params,
              ["fields", persistent_id, "list_entries"],
              list_entries
            )

            # Map.put(test_result_params, "value", List.first(new_urls))
            # :list ->
            #   Map.put(test_result_params, "list_entries", )
        end
      else
        test_result_params
      end
    end)
  end

  defp get_upload_urls(socket, upload_key) do
    {completed, []} = uploaded_entries(socket, upload_key)

    for entry <- completed do
      entry
      |> object_storage_key()
      |> ObjectStorage.get_url()
    end
  end

  defp consume_images(socket, %TestResult{} = test_result) do
    test_result.fields
    |> Enum.filter(fn field ->
      field.type == :image or field.subtype == :image
    end)
    |> Enum.each(fn field ->
      consume_uploaded_entries(socket, field.name, fn _meta, _entry -> {:ok, nil} end)
    end)

    {:ok, test_result}
  end

  defp object_storage_key(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "images/#{entry.uuid}.#{ext}"
  end
end
