defmodule PlantAidWeb.UserChannel do
  use PlantAidWeb, :channel

  @impl true
  def join("presence", _payload, socket) do
    PlantAid.ConnectionMonitor.monitor(socket.transport_pid, socket.assigns.user_id)
    {:ok, socket}
  end
end
