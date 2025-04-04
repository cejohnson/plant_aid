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
        <:subtitle>
          Add or update test results for an observation sample. Use Tab to advance through fields.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="test_result-form"
        phx-change="validate"
        phx-submit="save"
        phx-hook="OverrideEnter"
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
          <div class="items-top p-4 bg-neutral-200">
            <%= if length(Changeset.get_field(@form.source, :fields)) > 0 do %>
              <.label>Fields for the selected Diagnostic Method:</.label>
              <.inputs_for :let={f_field} field={@form[:fields]}>
                <div class="">
                  <%= case Changeset.get_field(f_field.source, :type) do %>
                    <% :string -> %>
                      <div class="bg-white p-2 my-2">
                        <.input
                          field={f_field[:value]}
                          type="text"
                          label={Changeset.get_field(f_field.source, :name)}
                          description={Changeset.get_field(f_field.source, :description)}
                        />
                      </div>
                    <% :image -> %>
                      <div class="bg-white p-2 my-2">
                        <div class="flex">
                          <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                          <div
                            :if={Changeset.get_field(f_field.source, :description)}
                            phx-click={JS.toggle(to: "##{f_field.id}-description")}
                          >
                            <.icon
                              name="hero-question-mark-circle-solid"
                              class="ml-1 h-4 w-4 text-zinc-700 cursor-pointer"
                            />
                          </div>
                        </div>
                        <div
                          :if={Changeset.get_field(f_field.source, :description)}
                          id={"#{f_field.id}-description"}
                          class="text-sm text-zinc-700"
                          hidden
                        >
                          <%= Changeset.get_field(f_field.source, :description) %>
                        </div>
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
                            <article class="py-2">
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
                                <p class="text-red-600 font-semibold"><%= error_to_string(err) %></p>
                              <% end %>
                            </article>
                          <% end %>

                          <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)]) do %>
                            <p class="text-red-600 font-semibold"><%= error_to_string(err) %></p>
                          <% end %>
                        </section>
                      </div>
                    <% :select -> %>
                      <div class="bg-white p-2 my-2">
                        <.input
                          field={f_field[:value]}
                          type="select"
                          label={Changeset.get_field(f_field.source, :name)}
                          description={Changeset.get_field(f_field.source, :description)}
                          prompt="Select"
                          options={
                            Enum.map(Changeset.get_field(f_field.source, :select_options), & &1.value)
                          }
                        />
                      </div>
                    <% :list -> %>
                      <div class="bg-white p-2 my-2">
                        <div class="flex">
                          <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                          <div
                            :if={Changeset.get_field(f_field.source, :description)}
                            phx-click={JS.toggle(to: "##{f_field.id}-description")}
                          >
                            <.icon
                              name="hero-question-mark-circle-solid"
                              class="ml-1 h-4 w-4 text-zinc-700 cursor-pointer"
                            />
                          </div>
                        </div>
                        <div
                          :if={Changeset.get_field(f_field.source, :description)}
                          id={"#{f_field.id}-description"}
                          class="text-sm text-zinc-700"
                          hidden
                        >
                          <%= Changeset.get_field(f_field.source, :description) %>
                        </div>
                        <%= case Changeset.get_field(f_field.source, :subtype) do %>
                          <% :string -> %>
                            <div class=" px-2">
                              <.inputs_for :let={f_entry} field={f_field[:list_entries]}>
                                <div class="flex ">
                                  <div class="grow">
                                    <input
                                      type="hidden"
                                      name={"test_result[fields][#{f_field.index}][list_entries_sort][]"}
                                      value={f_entry.index}
                                    />
                                    <.input field={f_entry[:value]} type="text" />
                                  </div>
                                  <button
                                    type="button"
                                    name={"test_result[fields][#{f_field.index}][list_entries_drop][]"}
                                    value={f_entry.index}
                                    phx-click={JS.dispatch("change")}
                                  >
                                    <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
                                  </button>
                                </div>
                              </.inputs_for>
                            </div>
                            <input
                              type="hidden"
                              name={"test_result[fields][#{f_field.index}][list_entries_drop][]"}
                            />

                            <button
                              type="button"
                              class="px-2"
                              name={"test_result[fields][#{f_field.index}][list_entries_sort][]"}
                              value="new"
                              phx-click={JS.dispatch("change")}
                            >
                              <.icon name="hero-plus-circle" />
                              <span class="align-middle">
                                Add Entry
                              </span>
                            </button>
                          <% :image -> %>
                            <%= if length(f_field.data.list_entries) > 0 do %>
                              <.label>Current Images</.label>
                              <.inputs_for :let={f_entry} field={f_field[:list_entries]}>
                                <.input field={f_entry[:delete]} type="checkbox" label="Delete" />
                                <img src={f_entry.data.value} height="200" width="200" />
                              </.inputs_for>
                            <% end %>
                            <.live_file_input upload={
                              @uploads[Changeset.get_field(f_field.source, :id)]
                            } />
                            <section
                              class="pt-2"
                              phx-drop-target={@uploads[Changeset.get_field(f_field.source, :id)].ref}
                            >
                              <%= for entry <- @uploads[Changeset.get_field(f_field.source, :id)].entries do %>
                                <article class="py-2">
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
                                    <p class="text-red-600 font-semibold">
                                      <%= error_to_string(err) %>
                                    </p>
                                  <% end %>
                                </article>
                              <% end %>

                              <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)]) do %>
                                <p class="text-red-600 font-semibold"><%= error_to_string(err) %></p>
                              <% end %>
                            </section>
                        <% end %>
                      </div>
                    <% :map -> %>
                      <div class="bg-white p-2 my-2">
                        <div class="flex">
                          <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                          <div
                            :if={Changeset.get_field(f_field.source, :description)}
                            phx-click={JS.toggle(to: "##{f_field.id}-description")}
                          >
                            <.icon
                              name="hero-question-mark-circle-solid"
                              class="ml-1 h-4 w-4 text-zinc-700 cursor-pointer"
                            />
                          </div>
                        </div>
                        <div
                          :if={Changeset.get_field(f_field.source, :description)}
                          id={"#{f_field.id}-description"}
                          class="text-sm text-zinc-700"
                          hidden
                        >
                          <%= Changeset.get_field(f_field.source, :description) %>
                        </div>
                        <.inputs_for :let={f_entry} field={f_field[:map_entries]}>
                          <div class="flex space-x-2">
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
                              class="px-2"
                              name={"test_result[fields][#{f_field.index}][map_entries_drop][]"}
                              value={f_entry.index}
                              phx-click={JS.dispatch("change")}
                            >
                              <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
                            </button>
                          </div>
                        </.inputs_for>

                        <input
                          type="hidden"
                          name={"test_result[fields][#{f_field.index}][map_entries_drop][]"}
                        />

                        <button
                          type="button"
                          class="px-2"
                          name={"test_result[fields][#{f_field.index}][map_entries_sort][]"}
                          value="new"
                          phx-click={JS.dispatch("change")}
                        >
                          <.icon name="hero-plus-circle" /><span class="align-middle">Add Entry</span>
                        </button>
                      </div>
                  <% end %>
                </div>
              </.inputs_for>
            <% end %>
            <div class="">
              <.inputs_for :let={f_pathology_result} field={@form[:pathology_results]}>
                <div class="bg-white p-4 my-2">
                  <.label>
                    <div class="text-lg">
                      <%= Changeset.get_field(f_pathology_result.source, :pathology).common_name %>
                    </div>
                  </.label>
                  <.radio_group class="py-2" field={f_pathology_result[:result]} label="Result">
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
                    <div class="font-bold">Fields</div>
                    <.inputs_for :let={f_field} field={f_pathology_result[:fields]}>
                      <div class="px-4">
                        <%= case Changeset.get_field(f_field.source, :type) do %>
                          <% :string -> %>
                            <.input
                              field={f_field[:value]}
                              type="text"
                              label={Changeset.get_field(f_field.source, :name)}
                              description={Changeset.get_field(f_field.source, :description)}
                            />
                          <% :image -> %>
                            <div class="flex">
                              <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                              <div
                                :if={Changeset.get_field(f_field.source, :description)}
                                phx-click={JS.toggle(to: "##{f_field.id}-description")}
                              >
                                <.icon
                                  name="hero-question-mark-circle-solid"
                                  class="ml-1 h-4 w-4 text-zinc-700 cursor-pointer"
                                />
                              </div>
                            </div>
                            <div
                              :if={Changeset.get_field(f_field.source, :description)}
                              id={"#{f_field.id}-description"}
                              class="text-sm text-zinc-700"
                              hidden
                            >
                              <%= Changeset.get_field(f_field.source, :description) %>
                            </div>
                            <%= if f_field.data.value do %>
                              <.label>Current Image</.label>
                              <.input field={f_field[:delete]} type="checkbox" label="Delete" />
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
                                <article class="py-2">
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
                                    <p class="text-red-600 font-semibold">
                                      <%= error_to_string(err) %>
                                    </p>
                                  <% end %>
                                </article>
                              <% end %>

                              <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)]) do %>
                                <p class="text-red-600 font-semibold"><%= error_to_string(err) %></p>
                              <% end %>
                            </section>
                          <% :select -> %>
                            <.input
                              field={f_field[:value]}
                              type="select"
                              label={Changeset.get_field(f_field.source, :name)}
                              description={Changeset.get_field(f_field.source, :description)}
                              prompt="Select"
                              options={
                                Enum.map(
                                  Changeset.get_field(f_field.source, :select_options),
                                  & &1.value
                                )
                              }
                            />
                          <% :list -> %>
                            <div class="flex">
                              <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                              <div
                                :if={Changeset.get_field(f_field.source, :description)}
                                phx-click={JS.toggle(to: "##{f_field.id}-description")}
                              >
                                <.icon
                                  name="hero-question-mark-circle-solid"
                                  class="ml-1 h-4 w-4 text-zinc-700 cursor-pointer"
                                />
                              </div>
                            </div>
                            <div
                              :if={Changeset.get_field(f_field.source, :description)}
                              id={"#{f_field.id}-description"}
                              class="text-sm text-zinc-700"
                              hidden
                            >
                              <%= Changeset.get_field(f_field.source, :description) %>
                            </div>
                            <%= case Changeset.get_field(f_field.source, :subtype) do %>
                              <% :string -> %>
                                <div>
                                  <.inputs_for :let={f_entry} field={f_field[:list_entries]}>
                                    <div class="flex ">
                                      <div class="grow">
                                        <input
                                          type="hidden"
                                          name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][list_entries_sort][]"}
                                          value={f_entry.index}
                                        />
                                        <.input field={f_entry[:value]} type="text" />
                                      </div>
                                      <button
                                        type="button"
                                        name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][list_entries_drop][]"}
                                        value={f_entry.index}
                                        phx-click={JS.dispatch("change")}
                                      >
                                        <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
                                      </button>
                                    </div>
                                  </.inputs_for>
                                </div>

                                <input
                                  type="hidden"
                                  name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][list_entries_drop][]"}
                                />

                                <button
                                  type="button"
                                  class="px-2"
                                  name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][list_entries_sort][]"}
                                  value="new"
                                  phx-click={JS.dispatch("change")}
                                >
                                  <.icon name="hero-plus-circle" />
                                  <span class="align-middle">
                                    Add Entry
                                  </span>
                                </button>
                              <% :image -> %>
                                <%= if length(f_field.data.list_entries) > 0 do %>
                                  <.label>Current Images</.label>
                                  <.inputs_for :let={f_entry} field={f_field[:list_entries]}>
                                    <.input field={f_entry[:delete]} type="checkbox" label="Delete" />
                                    <img src={f_entry.data.value} height="200" width="200" />
                                  </.inputs_for>
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
                                    <article class="py-2">
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
                                        <p class="text-red-600 font-semibold">
                                          <%= error_to_string(err) %>
                                        </p>
                                      <% end %>
                                    </article>
                                  <% end %>

                                  <%= for err <- upload_errors(@uploads[Changeset.get_field(f_field.source, :id)]) do %>
                                    <p class="text-red-600 font-semibold">
                                      <%= error_to_string(err) %>
                                    </p>
                                  <% end %>
                                </section>
                            <% end %>
                          <% :map -> %>
                            <div class="flex">
                              <.label><%= Changeset.get_field(f_field.source, :name) %></.label>
                              <div
                                :if={Changeset.get_field(f_field.source, :description)}
                                phx-click={JS.toggle(to: "##{f_field.id}-description")}
                              >
                                <.icon
                                  name="hero-question-mark-circle-solid"
                                  class="ml-1 h-4 w-4 text-zinc-700 cursor-pointer"
                                />
                              </div>
                            </div>
                            <div
                              :if={Changeset.get_field(f_field.source, :description)}
                              id={"#{f_field.id}-description"}
                              class="text-sm text-zinc-700"
                              hidden
                            >
                              <%= Changeset.get_field(f_field.source, :description) %>
                            </div>
                            <div>
                              <.inputs_for :let={f_entry} field={f_field[:map_entries]}>
                                <div class="flex space-x-2">
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
                                </div>
                              </.inputs_for>
                            </div>

                            <input
                              type="hidden"
                              name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][map_entries_drop][]"}
                            />

                            <button
                              type="button"
                              class="px-2"
                              name={"test_result[pathology_results][#{f_pathology_result.index}][fields][#{f_field.index}][map_entries_sort][]"}
                              value="new"
                              phx-click={JS.dispatch("change")}
                            >
                              <.icon name="hero-plus-circle" />
                              <span class="align-middle">
                                Add Entry
                              </span>
                            </button>
                        <% end %>
                      </div>
                    </.inputs_for>
                  <% end %>
                </div>
              </.inputs_for>
            </div>
          </div>
        <% end %>

        <.input
          name="notify_reporter"
          type="checkbox"
          label="Notify Observation Reporter"
          value={true}
        />
        <div>
          <.input name="create_alerts" type="checkbox" label="Create Alerts" value={true} />
          <div class="text-sm text-zinc-800 pl-8">
            If checked, this will create alerts for all users (other than you) who have alert subscriptions for confirmed diseases matching the location and pathology(ies) associated with this test result.
          </div>
        </div>

        <:actions>
          <.button variant="primary" phx-disable-with="Saving...">
            Save Test Result
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
    observation_id = Map.get(params, "observation_id")

    changeset =
      if observation_id do
        DiagnosticTests.change_test_result(test_result, %{"observation_id" => observation_id})
      else
        DiagnosticTests.change_test_result(test_result)
      end

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
    overrides = DiagnosticTests.get_diagnostic_method_overrides(diagnostic_method_id)

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

  def handle_event(
        "save",
        %{
          "test_result" => test_result_params,
          "notify_reporter" => notify_reporter,
          "create_alerts" => create_alerts
        },
        socket
      ) do
    changeset =
      DiagnosticTests.change_test_result(
        socket.assigns.test_result,
        socket.assigns.test_result_overrides,
        test_result_params
      )
      |> put_upload_urls(socket)

    save_test_result(
      socket,
      socket.assigns.live_action,
      changeset,
      notify_reporter,
      create_alerts
    )
  end

  defp save_test_result(socket, :edit, changeset, notify_reporter, create_alerts) do
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
             after_save: &consume_images(socket, &1),
             notify_reporter: notify_reporter,
             create_alerts: create_alerts
           ) do
        {:ok, test_result} ->
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

  defp save_test_result(socket, :new, changeset, notify_reporter, create_alerts) do
    with :ok <-
           Bodyguard.permit(
             DiagnosticTests,
             :create_test_result,
             socket.assigns.current_user
           ) do
      case DiagnosticTests.create_test_result(
             socket.assigns.current_user,
             changeset,
             after_save: &consume_images(socket, &1),
             notify_reporter: notify_reporter,
             create_alerts: create_alerts
           ) do
        {:ok, test_result} ->
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
      if Changeset.changed?(changeset, :fields) do
        changeset
        |> Changeset.update_change(:fields, fn field_changesets ->
          field_changesets
          |> Enum.reject(&(&1.action == :replace))
          |> Enum.map(&handle_field_upload_urls(&1, socket))
        end)
      else
        changeset
        |> Changeset.get_embed(:fields)
        |> Enum.map(&handle_field_upload_urls(&1, socket))
        |> then(&Changeset.put_embed(changeset, :fields, &1))
      end

    if Changeset.changed?(changeset, :pathology_results) do
      changeset
      |> Changeset.update_change(:pathology_results, fn pathology_result_changesets ->
        pathology_result_changesets
        |> Enum.reject(&(&1.action == :replace))
        |> Enum.map(fn pathology_result_changeset ->
          if Changeset.changed?(pathology_result_changeset, :fields) do
            pathology_result_changeset
            |> Changeset.update_change(:fields, fn field_changesets ->
              field_changesets
              |> Enum.reject(&(&1.action == :replace))
              |> Enum.map(&handle_field_upload_urls(&1, socket))
            end)
          else
            pathology_result_changeset
            |> Changeset.get_embed(:fields)
            |> Enum.map(&handle_field_upload_urls(&1, socket))
            |> then(&Changeset.put_embed(pathology_result_changeset, :fields, &1))
          end
        end)
      end)
    else
      changeset
      |> Changeset.get_assoc(:pathology_results)
      |> Enum.map(fn pathology_result_changeset ->
        pathology_result_changeset
        |> Changeset.get_embed(:fields)
        |> Enum.map(&handle_field_upload_urls(&1, socket))
        |> then(&Changeset.put_embed(pathology_result_changeset, :fields, &1))
      end)
      |> then(&Changeset.put_assoc(changeset, :pathology_results, &1))
    end
  end

  defp handle_field_upload_urls(field_changeset, socket) do
    field_changeset
    |> Changeset.get_field(:id)
    |> get_upload_urls(socket)
    |> put_field_upload_urls(field_changeset)
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
        |> then(&Changeset.put_embed(field_changeset, :list_entries, &1))
    end
  end

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
