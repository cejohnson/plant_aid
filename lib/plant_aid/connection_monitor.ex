defmodule PlantAid.ConnectionMonitor do
  use GenServer
  alias PlantAid.Accounts.UserConnectionEvent
  alias PlantAid.Repo

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def monitor(pid, user_id) do
    GenServer.call(__MODULE__, {:monitor, pid, user_id})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:monitor, pid, user_id}, _, %{} = state) do
    Process.monitor(pid)
    insert(user_id, :ws_connection)
    {:reply, :ok, Map.put(state, pid, user_id)}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {user_id, new_state} = Map.pop(state, pid)
    insert(user_id, :ws_disconnection)
    {:noreply, new_state}
  end

  defp insert(user_id, type) do
    Repo.insert(%UserConnectionEvent{
      user_id: user_id,
      type: type,
      timestamp: DateTime.utc_now(:second)
    })
  end
end
