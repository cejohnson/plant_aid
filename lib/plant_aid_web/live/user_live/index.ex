defmodule PlantAidWeb.UserLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Accounts
  alias PlantAid.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    current_user = socket.assigns.current_user

    socket =
      with :ok <- Bodyguard.permit(Accounts, :list_users, current_user) do
        case Accounts.list_users(params) do
          {:ok, {users, meta}} ->
            socket
            |> assign(:meta, meta)
            |> stream(:users, users, reset: true)

          {:error, _meta} ->
            socket
            |> put_flash(:error, "Something went wrong")
        end
      else
        _ ->
          socket
          |> put_flash(:error, "Unauthorized")
          |> push_navigate(to: ~p"/")
      end

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_info({PlantAidWeb.UserLive.FormComponent, {:saved, user}}, socket) do
    {:noreply, stream_insert(socket, :users, user)}
  end

  @impl true
  def handle_info({:updated_filters, params}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/users?#{params}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.delete_user(user)

    {:noreply, stream_delete(socket, :users, user)}
  end
end
