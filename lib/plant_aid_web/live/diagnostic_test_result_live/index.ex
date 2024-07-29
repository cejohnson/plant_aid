defmodule PlantAidWeb.DiagnosticTestResultLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.DiagnosticTests
  alias PlantAid.DiagnosticTests.TestResult

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :test_results, DiagnosticTests.list_test_results())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Test result")
    |> assign(:test_result, DiagnosticTests.get_test_result!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Test result")
    |> assign(:test_result, %TestResult{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Test results")
    |> assign(:test_result, nil)
  end

  @impl true
  def handle_info(
        {PlantAidWeb.DiagnosticTestResultLive.FormComponent, {:saved, test_result}},
        socket
      ) do
    {:noreply, stream_insert(socket, :test_results, test_result)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    test_result = DiagnosticTests.get_test_result!(id)
    {:ok, _} = DiagnosticTests.delete_test_result(test_result)

    {:noreply, stream_delete(socket, :test_results, test_result)}
  end
end
