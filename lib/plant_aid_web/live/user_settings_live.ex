defmodule PlantAidWeb.UserSettingsLive do
  use PlantAidWeb, :live_view

  import Ecto.Query

  alias PlantAid.Accounts

  def render(assigns) do
    ~H"""
    <.header>Notifications</.header>

    <%!-- <div>
      PlantAid can send you an email up to once a day with any new alerts from the previous 24 hours. This email will only be sent if there are new alerts to report.
    </div>
    <div>
      If you would like to receive these notifications, enable them here and choose when to receive them.
    </div> --%>

    <.simple_form
      for={@notifications_form}
      id="notifications_form"
      phx-submit="update_notifications_settings"
      phx-change="validate_notifications_settings"
      phx-hook="GetTimezone"
    >
      <.label>Daily Alerts</.label>
      <div>
        Send an email up to once a day with any new alerts from the previous 24 hours. An email will only be sent if there are new alerts to report.
      </div>
      <.input
        field={@notifications_form[:alerts_enabled]}
        type="checkbox"
        label="Send Alert Notifications"
      />
      <.input field={@notifications_form[:usage_summary_enabled]} type="checkbox" label="Send " />
      <.input field={@notifications_form[:time]} type="time" label="Time" />
      <.input
        field={@notifications_form[:timezone]}
        type="select"
        label="Timezone"
        options={@timezones}
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Notifications Settings</.button>
      </:actions>
    </.simple_form>

    <.header>Change Email</.header>

    <.simple_form
      for={@email_form}
      id="email_form"
      phx-submit="update_email"
      phx-change="validate_email"
    >
      <.input field={@email_form[:email]} type="email" label="Email" required />
      <.input
        field={@email_form[:current_password]}
        name="current_password"
        id="current_password_for_email"
        type="password"
        label="Current password"
        value={@email_form_current_password}
        required
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Email</.button>
      </:actions>
    </.simple_form>

    <.header>Change Password</.header>

    <.simple_form
      for={@password_form}
      id="password_form"
      action={~p"/users/log_in?_action=password_updated"}
      method="post"
      phx-change="validate_password"
      phx-submit="update_password"
      phx-trigger-action={@trigger_submit}
    >
      <.input field={@password_form[:email]} type="hidden" value={@current_email} />
      <.input field={@password_form[:password]} type="password" label="New password" required />
      <.input
        field={@password_form[:password_confirmation]}
        type="password"
        label="Confirm new password"
      />
      <.input
        field={@password_form[:current_password]}
        name="current_password"
        type="password"
        label="Current password"
        id="current_password_for_password"
        value={@current_password}
        required
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Password</.button>
      </:actions>
    </.simple_form>

    <.header>Change Name</.header>

    <.simple_form for={@name_form} id="name_form" phx-submit="update_name" phx-change="validate_name">
      <.input field={@name_form[:name]} type="text" label="Name" />
      <.input
        field={@name_form[:current_password]}
        name="current_password"
        id="current_password_for_name"
        type="password"
        label="Current password"
        value={@name_form_current_password}
        required
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Name</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    name_changeset = Accounts.change_user_name(user)
    notifications_changeset = Accounts.change_user_notifications_settings(user)

    # select * from users_notifications as un where extract(hour from concat((now() at time zone un.timezone)::date, ' ', un.time, ' ', un.timezone)::time with time zone at time zone 'UTC') = 15;

    timezones =
      from(
        tz in "pg_timezone_names",
        select: [:name],
        order_by: [:utc_offset, :name]
      )
      |> PlantAid.Repo.all()
      |> Enum.map(& &1.name)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:name_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:timezones, [{"Select", nil} | timezones])
      |> assign(:notifications_form, to_form(notifications_changeset))
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:name_form, to_form(name_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("browser_timezone", %{"timezone" => timezone}, socket) do
    case Phoenix.HTML.Form.input_value(socket.assigns.notifications_form, :timezone) do
      nil ->
        notifications_form =
          socket.assigns.current_user
          |> Accounts.change_user_notifications_settings(
            Map.put(socket.assigns.notifications_form.params, "timezone", timezone)
          )
          |> to_form()

        {:noreply, assign(socket, :notifications_form, notifications_form)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("validate_notifications_settings", params, socket) do
    IO.inspect(params, label: "vns params")
    %{"user" => user_params} = params

    notifications_form =
      socket.assigns.current_user
      |> Accounts.change_user_notifications_settings(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :notifications_form, notifications_form)}
  end

  def handle_event("update_notifications_settings", params, socket) do
    IO.inspect(params, label: "uns params")

    {:noreply, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("validate_name", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    name_form =
      socket.assigns.current_user
      |> Accounts.change_user_name(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, name_form: name_form, name_form_current_password: password)}
  end

  def handle_event("update_name", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_name(user, password, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Name changed successfully.")
         |> assign(name_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, name_form: to_form(changeset))}
    end
  end
end
