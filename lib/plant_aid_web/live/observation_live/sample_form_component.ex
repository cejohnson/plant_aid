defmodule PlantAidWeb.ObservationLive.SampleFormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.Diagnostics
  alias PlantAid.Observations
  alias PlantAid.Observations.Sample
  alias PlantAid.FormHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="sample-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:result]} type="select" options={@result_options} label="Result" />
        <.input field={@form[:confidence]} type="text" inputmode="decimal" label="Confidence" />
        <.input
          field={@form[:pathology_id]}
          type="select"
          options={@pathology_options}
          label="Pathology"
          phx-change="pathology-changed"
        />
        <%= if @genotype_options do %>
          <.input
            field={@form[:genotype_id]}
            type="select"
            options={@genotype_options}
            label="Genotype"
          />
        <% end %>
        <.input field={@form[:comments]} type="textarea" label="Comments" />

        <.input
          field={@form[:diagnostic_method_id]}
          type="select"
          options={@diagnostic_method_options}
          label="Diagnostic Method"
          prompt="Select"
          phx-change="diagnostic-method-changed"
        />

        <.label>Data</.label>
        <.inputs_for :let={f_data} field={@form[:data]}>
          <div class="flex space-x-2 items-center">
            <input type="hidden" name="sample[data_order][]" value={f_data.index} />
            <.input field={f_data[:key]} type="text" placeholder="Key" />
            <.input field={f_data[:value]} type="text" placeholder="Value" />
            <label class="cursor-pointer">
              <input type="checkbox" name="sample[data_delete][]" class="hidden" value={f_data.index} />
              <.icon name="hero-x-mark" />
            </label>
          </div>
        </.inputs_for>

        <label class="cursor-pointer">
          <input type="checkbox" name="sample[data_order][]" class="hidden" />
          <.icon name="hero-plus-circle" /><span class="align-middle">Add Key-Value Pair</span>
        </label>

        <%= if @form[:result].value in [:positive, "positive"] do %>
          <.input field={@form[:alert]} type="checkbox" label="Send Alerts" />
        <% end %>

        <:actions>
          <.button phx-disable-with="Saving...">Save sample</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{sample: sample} = assigns, socket) do
    result_options =
      Ecto.Enum.mappings(Sample, :result)
      |> Enum.map(fn {k, v} -> {String.capitalize(v), k} end)
      |> prepend_default_option()

    pathology_options = FormHelpers.list_pathology_options() |> prepend_default_option()

    genotype_options =
      case sample.pathology_id do
        nil ->
          nil

        id ->
          FormHelpers.list_genotype_options(id) |> prepend_default_option()
      end

    diagnostic_method_options =
      Diagnostics.list_diagnostic_methods()
      |> Enum.map(fn dm ->
        {dm.name, dm.id}
      end)

    changeset = Observations.change_sample(sample)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:result_options, result_options)
     |> assign(:pathology_options, pathology_options)
     |> assign(:genotype_options, genotype_options)
     |> assign(:diagnostic_method_options, diagnostic_method_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"sample" => sample_params}, socket) do
    changeset =
      socket.assigns.sample
      |> Observations.change_sample(sample_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"sample" => sample_params}, socket) do
    save_sample(socket, socket.assigns.action, sample_params)
  end

  def handle_event(
        "pathology-changed",
        %{"sample" => %{"pathology_id" => pathology_id}},
        socket
      ) do
    genotype_options =
      case pathology_id do
        "" ->
          nil

        id ->
          FormHelpers.list_genotype_options(id)
          |> prepend_default_option()
      end

    {:noreply, socket |> assign(:genotype_options, genotype_options)}
  end

  def handle_event(
        "diagnostic-method-changed",
        %{"sample" => %{"diagnostic_method_id" => diagnostic_method_id}},
        socket
      ) do
    diagnostic_method = Diagnostics.get_diagnostic_method!(diagnostic_method_id)

    data =
      diagnostic_method.field_names
      |> Enum.with_index(fn field_name, index ->
        {index, %{"key" => field_name.value}}
      end)
      |> Map.new()

    sample_params =
      Map.merge(socket.assigns.form.params, %{
        "data" => data
      })

    changeset =
      socket.assigns.sample
      |> Observations.change_sample(sample_params)

    {:noreply, socket |> assign_form(changeset)}
  end

  defp save_sample(socket, :edit_sample, sample_params) do
    case Observations.update_sample(socket.assigns.sample, sample_params) do
      {:ok, sample} ->
        if Map.get(sample_params, "alert") == "true" do
          Task.Supervisor.start_child(
            PlantAid.TaskSupervisor,
            PlantAid.Alerts,
            :handle_positive_sample,
            [sample]
          )
        end

        notify_parent({:saved, sample})

        {:noreply,
         socket
         |> put_flash(:info, "Sample updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_sample(socket, :add_sample, sample_params) do
    case Observations.create_sample(socket.assigns.id, sample_params) do
      {:ok, sample} ->
        if Map.get(sample_params, "alert") == "true" do
          Task.Supervisor.start_child(
            PlantAid.TaskSupervisor,
            PlantAid.Alerts,
            :handle_positive_sample,
            [sample]
          )
        end

        notify_parent({:saved, sample})

        {:noreply,
         socket
         |> put_flash(:info, "Sample created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp prepend_default_option(options) do
    [{"Select", nil}] ++ options
  end
end
