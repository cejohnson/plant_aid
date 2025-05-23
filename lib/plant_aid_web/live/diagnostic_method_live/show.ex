defmodule PlantAidWeb.DiagnosticMethodLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.DiagnosticMethods

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:diagnostic_method, DiagnosticMethods.get_diagnostic_method!(id))}
  end

  defp page_title(:show), do: "Show Diagnostic method"
  defp page_title(:edit), do: "Edit Diagnostic method"
end
