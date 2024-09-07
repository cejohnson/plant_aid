defmodule PlantAidWeb.DiagnosticTestResultLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.DiagnosticTests
  alias PlantAid.Hosts
  alias PlantAid.Pathologies

  @impl true
  def mount(_params, _session, socket) do
    pathology_options = Pathologies.list_pathologies() |> Enum.map(&{&1.common_name, &1.id})
    host_options = Hosts.list_hosts() |> Enum.map(&{&1.common_name, &1.id})

    filter_fields = [
      updated_on: [
        label: "From",
        op: :>=,
        type: "date"
      ],
      updated_on: [
        label: "To",
        op: :<=,
        type: "date"
      ],
      result: [
        label: "Result",
        type: "select",
        options: [
          {"Any", nil},
          {"Positive", :positive},
          {"Negative", :negative}
        ]
      ],
      host_id: [
        label: "Host",
        type: "select",
        options: [
          {"Any", nil} | host_options
        ]
      ],
      pathology_id: [
        label: "Pathology",
        type: "select",
        options: [
          {"Any", nil} | pathology_options
        ]
      ]
    ]

    {:ok,
     socket
     |> assign(:page_title, "Listing Test results")
     |> assign(:base_filter_fields, filter_fields)
     |> assign(:filter_fields, filter_fields)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      case DiagnosticTests.list_test_results(socket.assigns.current_user, params) do
        {:ok, {test_results, meta}} ->
          socket
          |> assign(:meta, meta)
          |> stream(:test_results, test_results, reset: true)
          |> maybe_add_genotype_filter_field(meta.flop)

        {:error, _meta} ->
          socket
          |> put_flash(:error, "Something went wrong")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    test_result = DiagnosticTests.get_test_result!(id)
    {:ok, _} = DiagnosticTests.delete_test_result(test_result)

    {:noreply, stream_delete(socket, :test_results, test_result)}
  end

  @impl true
  def handle_event("update-filter", params, socket) do
    {:noreply, push_patch(socket, to: ~p"/test_results?#{params}")}
  end

  @impl true
  def handle_event("reset-filter", params, socket) do
    params = Map.drop(params, ["page", "filters"])
    {:noreply, push_patch(socket, to: ~p"/test_results?#{params}")}
  end

  defp maybe_add_genotype_filter_field(socket, %Flop{} = flop) do
    case Flop.Filter.get_value(flop.filters, :pathology_id) do
      nil ->
        assign(socket, :filter_fields, socket.assigns.base_filter_fields)

      pathology_id ->
        genotype_options = Pathologies.list_genotypes(pathology_id) |> Enum.map(&{&1.name, &1.id})

        filter_fields =
          socket.assigns.base_filter_fields ++
            [
              genotype_id: [
                label: "Genotype",
                type: "select",
                options: [{"Any", nil} | genotype_options]
              ]
            ]

        assign(socket, :filter_fields, filter_fields)
    end
  end
end
