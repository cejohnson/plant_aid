defmodule PlantAidWeb.DiagnosticTestResultLive.Form do
  use PlantAidWeb, :live_view

  alias Ecto.Changeset
  alias PlantAid.DiagnosticMethods
  alias PlantAid.DiagnosticTests
  alias PlantAid.ObjectStorage
  alias PlantAid.DiagnosticTests.Field
  alias PlantAid.DiagnosticTests.TestResult

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @page_title %>
        <:subtitle>Use this form to manage test_result records in your database.</:subtitle>
      </.header>

      <.simple_form for={@form} id="test_result-form" phx-change="validate" phx-submit="save">
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
          <%= if length(Changeset.get_field(@form.source, :fields)) > 0 do %>
            <.label>Fields</.label>
            <.inputs_for :let={f_field} field={@form[:fields]}>
              <%= case Changeset.get_field(f_field.source, :type) do %>
                <% :string -> %>
                  <.input
                    field={f_field[:value]}
                    type="text"
                    label={Changeset.get_field(f_field.source, :name)}
                  />
                <% :image -> %>
                  <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                  <%= if f_field.data.value do %>
                    <.label>Current Image</.label>
                    <.input field={f_field[:delete]} type="checkbox" label="Delete" />
                    <img src={f_field.data.value} height="200" width="200" />
                  <% end %>
                  <.live_file_input upload={@uploads[Changeset.get_field(f_field.source, :id)]} />
                  <section
                    class="pt-2"
                    phx-drop-target={@uploads[Changeset.get_field(f_field.source, :id)].ref}
                  >
                    <%= for entry <- @uploads[Changeset.get_field(f_field.source, :id)].entries do %>
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
                          phx-value-ref={"#{Changeset.get_field(f_field.source, :id)}|#{entry.ref}"}
                          aria-label="cancel"
                        >
                          &times;
                        </.button>

                        <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)], entry) do %>
                          <p><%= error_to_string(err) %></p>
                        <% end %>
                      </article>
                    <% end %>

                    <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)]) do %>
                      <p><%= error_to_string(err) %></p>
                    <% end %>
                  </section>
                <% :select -> %>
                  <.input
                    field={f_field[:value]}
                    type="select"
                    label={Changeset.get_field(f_field.source, :name)}
                    prompt="Select"
                    options={
                      Enum.map(Changeset.get_field(f_field.source, :select_options), & &1.value)
                    }
                  />
                <% :list -> %>
                  <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                  <%= case Changeset.get_field(f_field.source, :subtype) do %>
                    <% :string -> %>
                      <div>
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
                      </div>
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
                        <.inputs_for :let={f_entry} field={f_field[:list_entries]}>
                          <.input field={f_entry[:delete]} type="checkbox" label="Delete" />
                          <img src={f_entry.data.value} height="200" width="200" />
                        </.inputs_for>
                        <%!-- <%= for entry <- Changeset.get_embed do %>
                          <.input type="checkbox" name={"test_result[fields][#{f_field.index}][list_entries_drop][]"} label="Delete" />
                          <img src={entry.value} height="200" width="200" />
                        <% end %> --%>
                      <% end %>
                      <.live_file_input upload={@uploads[Changeset.get_field(f_field.source, :id)]} />
                      <section
                        class="pt-2"
                        phx-drop-target={@uploads[Changeset.get_field(f_field.source, :id)].ref}
                      >
                        <%= for entry <- @uploads[Changeset.get_field(f_field.source, :id)].entries do %>
                          <article>
                            <figure>
                              <.live_img_preview entry={entry} width={200} />
                              <figcaption><%= entry.client_name %></figcaption>
                            </figure>

                            <progress value={entry.progress} max="100">
                              <%= entry.progress %>%
                            </progress>

                            <.button
                              type="button"
                              class="bg-stone-500"
                              phx-click="cancel-upload"
                              phx-value-ref={"#{Changeset.get_field(f_field.source, :id)}|#{entry.ref}"}
                              aria-label="cancel"
                            >
                              &times;
                            </.button>

                            <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)], entry) do %>
                              <p><%= error_to_string(err) %></p>
                            <% end %>
                          </article>
                        <% end %>

                        <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)]) do %>
                          <p><%= error_to_string(err) %></p>
                        <% end %>
                      </section>
                  <% end %>
                <% :map -> %>
                  <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                  <div>
                    <.inputs_for :let={f_entry} field={f_field[:map_entries]}>
                      <input
                        type="hidden"
                        name={"test_result[fields][#{f_field.index}][map_entries_sort][]"}
                        value={f_entry.index}
                      />
                      <.input field={f_entry[:key]} type="text" label="Key" />
                      <%= case Changeset.get_field(f_field.source, :subtype) do %>
                        <% :string -> %>
                          <.input field={f_entry[:value]} type="text" label="Value" />
                        <% :select -> %>
                          <.input
                            field={f_entry[:value]}
                            type="select"
                            label="Value"
                            prompt="Select"
                            options={
                              Enum.map(
                                Changeset.get_field(f_field.source, :select_options),
                                & &1.value
                              )
                            }
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
                  </div>

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
            </.inputs_for>
          <% end %>

          <.inputs_for :let={f_pathology_result} field={@form[:pathology_results]}>
            <.label>
              <%= Changeset.get_field(f_pathology_result.source, :pathology).common_name %>
            </.label>
            <.radio_group field={f_pathology_result[:result]} label="Result">
              <:radio value="positive">Positive</:radio>
              <:radio value="negative">Negative</:radio>
            </.radio_group>
            <%= if Changeset.get_field(f_pathology_result.source, :result) == :positive and length(Changeset.get_field(f_pathology_result.source, :pathology).genotypes) > 0 do %>
              <.input
                field={f_pathology_result[:genotype_id]}
                type="select"
                label="Genotype"
                prompt="Select"
                options={
                  Enum.map(
                    Changeset.get_field(f_pathology_result.source, :pathology).genotypes,
                    &{&1.name, &1.id}
                  )
                }
              />
            <% end %>
            <%= if length(Changeset.get_field(f_pathology_result.source, :fields)) > 0 do %>
              <.label>Fields</.label>
              <.inputs_for :let={f_field} field={f_pathology_result[:fields]}>
                <%= case Changeset.get_field(f_field.source, :type) do %>
                  <% :string -> %>
                    <.input
                      field={f_field[:value]}
                      type="text"
                      label={Changeset.get_field(f_field.source, :name)}
                    />
                  <% :image -> %>
                    <% IO.puts("printing image") %>
                    <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                    <%= if f_field.data.value do %>
                      <.label>Current Image</.label>
                      <img src={f_field.data.value} height="200" width="200" />
                    <% end %>
                    <.live_file_input upload={
                      @uploads[
                        Changeset.get_field(f_field.source, :id)
                      ]
                    } />
                    <section
                      class="pt-2"
                      phx-drop-target={
                        @uploads[
                          Changeset.get_field(f_field.source, :id)
                        ].ref
                      }
                    >
                      <%= for entry <- @uploads[Changeset.get_field(f_field.source, :id)].entries do %>
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
                            phx-value-ref={"#{Changeset.get_field(f_field.source, :id)}|#{entry.ref}"}
                            aria-label="cancel"
                          >
                            &times;
                          </.button>

                          <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)], entry) do %>
                            <p><%= error_to_string(err) %></p>
                          <% end %>
                        </article>
                      <% end %>

                      <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)]) do %>
                        <p><%= error_to_string(err) %></p>
                      <% end %>
                    </section>
                  <% :select -> %>
                    <.input
                      field={f_field[:value]}
                      type="select"
                      label={Changeset.get_field(f_field.source, :name)}
                      prompt="Select"
                      options={
                        Enum.map(Changeset.get_field(f_field.source, :select_options), & &1.value)
                      }
                    />
                  <% :list -> %>
                    <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                    <%= case Changeset.get_field(f_field.source, :subtype) do %>
                      <% :string -> %>
                        <div>
                          <.inputs_for :let={f_entry} field={f_field[:list_entries]}>
                            <input
                              type="hidden"
                              name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][list_entries_sort][]"}
                              value={f_entry.index}
                            />
                            <.input field={f_entry[:value]} type="text" />
                            <button
                              type="button"
                              name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][list_entries_drop][]"}
                              value={f_entry.index}
                              phx-click={JS.dispatch("change")}
                            >
                              <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
                            </button>
                          </.inputs_for>
                        </div>

                        <input
                          type="hidden"
                          name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][list_entries_drop][]"}
                        />

                        <button
                          type="button"
                          name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][list_entries_sort][]"}
                          value="new"
                          phx-click={JS.dispatch("change")}
                        >
                          <.icon name="hero-plus-circle" /><span class="align-middle">Add Entry</span>
                        </button>
                      <% :image -> %>
                        <% IO.puts("printing images") %>
                        <%= if length(f_field.data.list_entries) > 0 do %>
                          <.label>Current Images</.label>
                          <%= for entry <- f_field.data.list_entries do %>
                            <img src={entry.value} height="200" width="200" />
                          <% end %>
                        <% end %>
                        <.live_file_input upload={
                          @uploads[
                            Changeset.get_field(f_field.source, :id)
                          ]
                        } />
                        <section
                          class="pt-2"
                          phx-drop-target={
                            @uploads[
                              Changeset.get_field(f_field.source, :id)
                            ].ref
                          }
                        >
                          <%= for entry <- @uploads[Changeset.get_field(f_field.source, :id)].entries do %>
                            <article>
                              <figure>
                                <.live_img_preview entry={entry} width={200} />
                                <figcaption><%= entry.client_name %></figcaption>
                              </figure>

                              <progress value={entry.progress} max="100">
                                <%= entry.progress %>%
                              </progress>

                              <.button
                                type="button"
                                class="bg-stone-500"
                                phx-click="cancel-upload"
                                phx-value-ref={"#{Changeset.get_field(f_field.source, :id)}|#{entry.ref}"}
                                aria-label="cancel"
                              >
                                &times;
                              </.button>

                              <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)], entry) do %>
                                <p><%= error_to_string(err) %></p>
                              <% end %>
                            </article>
                          <% end %>

                          <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)]) do %>
                            <p><%= error_to_string(err) %></p>
                          <% end %>
                        </section>
                    <% end %>
                  <% :map -> %>
                    <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                    <div>
                      <.inputs_for :let={f_entry} field={f_field[:map_entries]}>
                        <input
                          type="hidden"
                          name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][map_entries_sort][]"}
                          value={f_entry.index}
                        />
                        <.input field={f_entry[:key]} type="text" label="Key" />
                        <%= case Changeset.get_field(f_field.source, :subtype) do %>
                          <% :string -> %>
                            <.input field={f_entry[:value]} type="text" label="Value" />
                          <% :select -> %>
                            <.input
                              field={f_entry[:value]}
                              type="select"
                              label="Value"
                              prompt="Select"
                              options={
                                Enum.map(
                                  Changeset.get_field(f_field.source, :select_options),
                                  & &1.value
                                )
                              }
                            />
                        <% end %>
                        <button
                          type="button"
                          name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][map_entries_drop][]"}
                          value={f_entry.index}
                          phx-click={JS.dispatch("change")}
                        >
                          <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
                        </button>
                      </.inputs_for>
                    </div>

                    <input
                      type="hidden"
                      name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][map_entries_drop][]"}
                    />

                    <button
                      type="button"
                      name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][map_entries_sort][]"}
                      value="new"
                      phx-click={JS.dispatch("change")}
                    >
                      <.icon name="hero-plus-circle" /><span class="align-middle">Add Entry</span>
                    </button>
                <% end %>
              </.inputs_for>
            <% end %>
          </.inputs_for>
        <% end %>

        <:actions>
          <.button variant="primary" phx-disable-with="Saving...">
            Save Diagnostic test result
          </.button>
          <.button variant="secondary" type="button" phx-click="reset">Reset</.button>
          <.button type="button" phx-click="cancel">Cancel</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    diagnostic_method_options =
      DiagnosticMethods.list_diagnostic_methods() |> Enum.map(&{&1.name, &1.id})

    {:ok,
     socket
     |> assign(:diagnostic_method_options, diagnostic_method_options)
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_params(params, url, socket) do
    test_result = get_test_result(socket.assigns.live_action, params)

    changeset = DiagnosticTests.change_test_result(test_result)

    # TODO: handle observation_id query param
    {:noreply,
     socket
     |> allow_field_upload(changeset)
     |> assign(:url, url)
     |> assign(:test_result, test_result)
     |> assign(:test_result_overrides, nil)
     |> assign_form(changeset)}
  end

  defp get_test_result(:edit, %{"id" => id}) do
    DiagnosticTests.get_test_result!(id)
  end

  defp get_test_result(:new, _) do
    %TestResult{pathology_results: []}
  end

  @impl true
  def handle_event("validate", %{"test_result" => test_result_params}, socket) do
    changeset =
      socket.assigns.test_result
      |> DiagnosticTests.change_test_result(
        socket.assigns.test_result_overrides,
        test_result_params
      )
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign_form(changeset)}
  end

  def handle_event("reset", _, socket) do
    changeset = DiagnosticTests.change_test_result(socket.assigns.test_result)

    {:noreply,
     socket
     |> assign(:test_result_overrides, nil)
     |> assign_form(changeset)}
  end

  def handle_event("cancel", _, socket) do
    to =
      if String.contains?(socket.assigns.url, "show") do
        ~p"/test_results/#{socket.assigns.test_result}"
      else
        ~p"/test_results"
      end

    {:noreply,
     socket
     |> push_navigate(to: to)}
  end

  def handle_event(
        "change-diagnostic-method",
        %{"test_result" => %{"diagnostic_method_id" => diagnostic_method_id}},
        socket
      ) do
    overrides =
      DiagnosticTests.get_diagnostic_method_overrides(diagnostic_method_id)
      |> IO.inspect(label: "field overrides")

    changeset =
      socket.assigns.form.params
      |> Map.put("diagnostic_method_id", diagnostic_method_id)
      |> then(&DiagnosticTests.change_test_result(socket.assigns.test_result, overrides, &1))

    {:noreply,
     socket
     |> allow_field_upload(changeset)
     |> assign(:test_result_overrides, overrides)
     |> assign_form(changeset)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    [name, ref] = String.split(ref, "|")
    {:noreply, cancel_upload(socket, name, ref)}
  end

  def handle_event("save", %{"test_result" => test_result_params}, socket) do
    changeset =
      DiagnosticTests.change_test_result(
        socket.assigns.test_result,
        socket.assigns.test_result_overrides,
        test_result_params
      )
      |> put_upload_urls(socket)

    save_test_result(socket, socket.assigns.live_action, changeset)
  end

  defp save_test_result(socket, :edit, changeset) do
    with :ok <-
           Bodyguard.permit(
             DiagnosticTests,
             :update_test_result,
             socket.assigns.current_user,
             socket.assigns.test_result
           ) do
      case DiagnosticTests.update_test_result(
             socket.assigns.current_user,
             changeset,
             &consume_images(socket, &1)
           ) do
        {:ok, test_result} ->
          notify_parent({:saved, test_result})

          {:noreply,
           socket
           |> put_flash(:info, "Test result updated successfully")
           |> push_navigate(to: ~p"/test_results/#{test_result}")}

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

  defp save_test_result(socket, :new, changeset) do
    with :ok <-
           Bodyguard.permit(
             DiagnosticTests,
             :create_test_result,
             socket.assigns.current_user
           ) do
      case DiagnosticTests.create_test_result(
             socket.assigns.current_user,
             changeset,
             &consume_images(socket, &1)
           ) do
        {:ok, test_result} ->
          notify_parent({:saved, test_result})

          {:noreply,
           socket
           |> put_flash(:info, "Test result created successfully")
           |> push_navigate(to: ~p"/test_results/#{test_result}")}

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

  defp allow_field_upload(socket, changeset) do
    changeset
    |> Changeset.get_field(:pathology_results)
    |> Enum.map(& &1.fields)
    |> List.flatten()
    |> Enum.concat(Changeset.get_field(changeset, :fields))
    |> Enum.filter(&(&1.type == :image or &1.subtype == :image))
    |> Enum.reduce(socket, fn field, socket ->
      max_entries = if field.type == :image, do: 1, else: 20

      allow_upload(socket, field.id,
        accept: ~w(.jpg .jpeg .png),
        max_entries: max_entries,
        external: &presign_upload/2
      )
    end)
  end

  defp put_upload_urls(changeset, socket) do
    changeset =
      changeset
      |> Changeset.get_embed(:fields)
      |> Enum.map(&handle_field_upload_urls(&1, socket))
      |> IO.inspect(label: "fields changesets")
      |> then(&Changeset.put_embed(changeset, :fields, &1))
      |> IO.inspect(label: "changeset with added fields with urls")

    changeset
    |> Changeset.get_assoc(:pathology_results)
    |> Enum.map(fn pathology_result_changeset ->
      pathology_result_changeset
      |> Changeset.get_embed(:fields)
      |> Enum.map(&handle_field_upload_urls(&1, socket))
      |> then(&Changeset.put_embed(pathology_result_changeset, :fields, &1))
    end)
    |> then(&Changeset.put_assoc(changeset, :pathology_results, &1))
    |> IO.inspect(label: "final put_upload_urls changeset")
  end

  defp handle_field_upload_urls(field_changeset, socket) do
    field_changeset
    |> Changeset.get_field(:id)
    |> IO.inspect(label: "field id")
    |> get_upload_urls(socket)
    |> IO.inspect(label: "field urls")
    |> put_field_upload_urls(field_changeset)
    |> IO.inspect(label: "field changeset")
  end

  defp get_upload_urls(upload_key, socket) do
    {completed, []} = uploaded_entries(socket, upload_key)

    for entry <- completed do
      entry
      |> object_storage_key()
      |> ObjectStorage.get_url()
    end
    |> Enum.reverse()
  end

  defp put_field_upload_urls([], field_changeset), do: field_changeset

  defp put_field_upload_urls(urls, field_changeset) do
    case Changeset.get_field(field_changeset, :type) do
      :image ->
        Changeset.put_change(field_changeset, :value, List.first(urls))

      :list ->
        list_entries =
          Enum.map(urls, fn url ->
            %Field.ListEntry{value: url}
          end)

        field_changeset
        |> Changeset.get_field(:list_entries)
        |> Enum.concat(list_entries)
        |> then(&Changeset.put_change(field_changeset, :list_entries, &1))
    end
  end

  # def put_upload_urls(%TestResult{} = test_result, test_result_params, socket) do
  #   IO.inspect(test_result_params, label: "put_upload_url params")

  #   test_result_params =
  #     test_result_params["fields"]
  #     |> Enum.filter(fn {_persistent_id, field} ->
  #       field["type"] == "image" or field["subtype"] == "image"
  #     end)
  #     |> Enum.reduce(test_result_params, fn {persistent_id, field}, test_result_params ->
  #       new_urls =
  #         get_upload_urls(socket, field["name"])

  #       if length(new_urls) > 0 do
  #         # persistent_id =
  #         #   Enum.find_value(
  #         #     test_result_params["fields"],
  #         #     fn {persistent_id, field_params} ->
  #         #       if field.id == field_params["id"], do: persistent_id
  #         #     end
  #         #   )

  #         # TODO: we need to delete old images here
  #         case field["type"] do
  #           "image" ->
  #             put_in(
  #               test_result_params,
  #               ["fields", persistent_id, "value"],
  #               List.first(new_urls)
  #             )

  #           "list" ->
  #             new_list_entries =
  #               new_urls
  #               |> Enum.map(fn url ->
  #                 %{"value" => url}
  #               end)

  #             list_entries =
  #               test_result.fields
  #               |> Enum.find_value([], fn field ->
  #                 if field.id == field["id"], do: persistent_id
  #               end)
  #               |> Enum.map(&Map.from_struct/1)
  #               |> Enum.concat(new_list_entries)

  #             put_in(
  #               test_result_params,
  #               ["fields", persistent_id, "list_entries"],
  #               list_entries
  #             )

  #             # Map.put(test_result_params, "value", List.first(new_urls))
  #             # :list ->
  #             #   Map.put(test_result_params, "list_entries", )
  #         end
  #       else
  #         test_result_params
  #       end
  #     end)

  #   test_result_params["pathology_results"]
  #   |> Enum.reduce(test_result_params, fn {index, pathology_result_params}, test_result_params ->
  #     pathology_result_params["fields"]
  #     |> Enum.filter(fn {_persistent_id, field} ->
  #       field["type"] == "image" or field["subtype"] == "image"
  #     end)
  #     |> Enum.reduce(test_result_params, fn {persistent_id, field}, test_result_params ->
  #       upload_name = "pathology_results_#{index}_#{field["name"]}"

  #       new_urls =
  #         get_upload_urls(socket, upload_name)

  #       IO.inspect(new_urls, label: "new urls")

  #       if length(new_urls) > 0 do
  #         # persistent_id =
  #         #   Enum.find_value(
  #         #     test_result_params["fields"],
  #         #     fn {persistent_id, field_params} ->
  #         #       if field.id == field_params["id"], do: persistent_id
  #         #     end
  #         #   )

  #         # TODO: we need to delete old images here
  #         case field["type"] do
  #           "image" ->
  #             put_in(
  #               test_result_params,
  #               ["pathology_results", index, "fields", persistent_id, "value"],
  #               List.first(new_urls)
  #             )

  #           "list" ->
  #             new_list_entries =
  #               new_urls
  #               |> Enum.map(fn url ->
  #                 %{"value" => url}
  #               end)

  #             list_entries =
  #               test_result.fields
  #               |> Enum.find_value([], fn field ->
  #                 if field.id == field["id"], do: field.list_entries
  #               end)
  #               |> Enum.map(&Map.from_struct/1)
  #               |> Enum.concat(new_list_entries)

  #             put_in(
  #               test_result_params,
  #               ["pathology_results", index, "fields", persistent_id, "list_entries"],
  #               list_entries
  #             )

  #             # Map.put(test_result_params, "value", List.first(new_urls))
  #             # :list ->
  #             #   Map.put(test_result_params, "list_entries", )
  #         end
  #       else
  #         test_result_params
  #       end
  #     end)
  #   end)

  #   # test_result.pathology_results
  #   # |> Enum.with_index()
  #   # |> Enum.reduce(params, fn {pathology_result, index}, test_result_params ->
  #   #   pathology_result.fields
  #   #   |> Enum.filter(fn field ->
  #   #     field.type == :image or field.subtype == :image
  #   #   end)
  #   #   |> Enum.reduce(test_result_params, fn field, test_result_params ->
  #   #     upload_name = "pathology_results_#{index}_#{field.name}"

  #   #     new_urls =
  #   #       get_upload_urls(socket, upload_name)

  #   #     if length(new_urls) > 0 do
  #   #       persistent_id =
  #   #         Enum.find_value(
  #   #           test_result_params["fields"],
  #   #           fn {persistent_id, field_params} ->
  #   #             if field.id == field_params["id"], do: persistent_id
  #   #           end
  #   #         )

  #   #       # TODO: we need to delete old images here
  #   #       case field.type do
  #   #         :image ->
  #   #           put_in(
  #   #             test_result_params,
  #   #             ["fields", persistent_id, "value"],
  #   #             List.first(new_urls)
  #   #           )

  #   #         :list ->
  #   #           list_entries =
  #   #             new_urls
  #   #             |> Enum.map(fn url ->
  #   #               %{"value" => url}
  #   #             end)

  #   #           list_entries =
  #   #             field.list_entries
  #   #             |> Enum.map(&Map.from_struct/1)
  #   #             |> Enum.concat(list_entries)

  #   #           put_in(
  #   #             test_result_params,
  #   #             ["fields", persistent_id, "list_entries"],
  #   #             list_entries
  #   #           )

  #   #           # Map.put(test_result_params, "value", List.first(new_urls))
  #   #           # :list ->
  #   #           #   Map.put(test_result_params, "list_entries", )
  #   #       end
  #   #     else
  #   #       test_result_params
  #   #     end
  #   #   end)
  #   # end)
  # end

  defp consume_images(socket, %TestResult{} = test_result) do
    test_result.fields
    |> Enum.filter(fn field ->
      field.type == :image or field.subtype == :image
    end)
    |> Enum.each(fn field ->
      consume_uploaded_entries(socket, field.id, fn _meta, _entry -> {:ok, nil} end)
    end)

    test_result.pathology_results
    |> Enum.each(fn pathology_result ->
      pathology_result.fields
      |> Enum.filter(fn field ->
        field.type == :image or field.subtype == :image
      end)
      |> Enum.each(fn field ->
        consume_uploaded_entries(socket, field.id, fn _meta, _entry ->
          {:ok, nil}
        end)
      end)
    end)

    {:ok, test_result}
  end

  defp object_storage_key(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "images/#{entry.uuid}.#{ext}"
  end

  defp page_title(:new), do: "New Test Result"
  defp page_title(:edit), do: "Edit Test Result"
end
