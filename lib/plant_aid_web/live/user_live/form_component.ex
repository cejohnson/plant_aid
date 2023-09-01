defmodule PlantAidWeb.UserLive.FormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.Accounts
  alias PlantAid.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage user records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:email]} type="email" label="Email" />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:roles]} type="select" multiple label="Roles" options={@role_options} />
        <%= if @id == :new do %>
          <.input field={@form[:invite]} type="checkbox" label="Send Invitation Email" />
        <% end %>

        <:actions>
          <.button variant="primary" phx-disable-with="Saving...">Save User</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = Accounts.change_user(user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign_role_options()}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    with :ok <-
           Bodyguard.permit(
             Accounts,
             :update_user,
             socket.assigns.current_user,
             socket.assigns.user
           ) do
      case Accounts.update_user(socket.assigns.user, user_params) do
        {:ok, user} ->
          notify_parent({:saved, user})

          {:noreply,
           socket
           |> put_flash(:info, "User updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    end
  end

  defp save_user(socket, :new, user_params) do
    with :ok <- Bodyguard.permit(Accounts, :create_user, socket.assigns.current_user) do
      case Accounts.create_user(user_params) do
        {:ok, user} ->
          if Map.get(user_params, "invite") == "true" do
            {:ok, _} =
              Accounts.deliver_user_invite(
                user,
                socket.assigns.current_user,
                &url(~p"/users/invite/#{&1}")
              )
          end

          notify_parent({:saved, user})

          {:noreply,
           socket
           |> put_flash(:info, "User created successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_role_options(socket) do
    current_user = socket.assigns.current_user
    options = [{"None", nil}, {"Researcher", :researcher}, {"Admin", :admin}]

    options =
      if User.has_role?(current_user, :superuser) do
        options ++ [{"Superuser", :superuser}]
      else
        options
      end

    assign(socket, :role_options, options)
  end
end
