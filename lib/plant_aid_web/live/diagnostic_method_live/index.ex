defmodule PlantAidWeb.DiagnosticMethodLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.DiagnosticMethods
  alias PlantAid.DiagnosticMethods.DiagnosticMethod

  @impl true
  @spec mount(any(), any(), Phoenix.LiveView.Socket.t()) :: {:ok, any()}
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :diagnostic_methods, DiagnosticMethods.list_diagnostic_methods())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Diagnostic method")
    |> assign(:diagnostic_method, DiagnosticMethods.get_diagnostic_method!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Diagnostic method")
    |> assign(:diagnostic_method, %DiagnosticMethod{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Diagnostic methods")
    |> assign(:diagnostic_method, nil)
  end

  @impl true
  def handle_info(
        {PlantAidWeb.DiagnosticMethodLive.FormComponent, {:saved, diagnostic_method}},
        socket
      ) do
    {:noreply, stream_insert(socket, :diagnostic_methods, diagnostic_method)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    diagnostic_method = DiagnosticMethods.get_diagnostic_method!(id)

    case DiagnosticMethods.delete_diagnostic_method(diagnostic_method) do
      {:ok, _} ->
        {:noreply, stream_delete(socket, :diagnostic_methods, diagnostic_method)}

      {:error, _} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Error deleting diagnostic method, existing test results are associated with it."
         )}
    end
  end
end
