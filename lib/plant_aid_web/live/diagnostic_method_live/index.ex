defmodule PlantAidWeb.DiagnosticMethodLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Diagnostics
  alias PlantAid.Diagnostics.DiagnosticMethod

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :diagnostic_methods, Diagnostics.list_diagnostic_methods())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Diagnostic method")
    |> assign(:diagnostic_method, Diagnostics.get_diagnostic_method!(id))
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
  def handle_info({PlantAidWeb.DiagnosticMethodLive.FormComponent, {:saved, diagnostic_method}}, socket) do
    {:noreply, stream_insert(socket, :diagnostic_methods, diagnostic_method)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    diagnostic_method = Diagnostics.get_diagnostic_method!(id)
    {:ok, _} = Diagnostics.delete_diagnostic_method(diagnostic_method)

    {:noreply, stream_delete(socket, :diagnostic_methods, diagnostic_method)}
  end
end
