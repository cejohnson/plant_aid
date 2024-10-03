defmodule PlantAid.Workers.SendEmailDigest do
  require Logger
  use Oban.Worker

  use Phoenix.VerifiedRoutes,
    endpoint: PlantAidWeb.Endpoint,
    router: PlantAidWeb.Router,
    statics: PlantAidWeb.static_paths()

  alias PlantAid.Accounts
  alias PlantAid.Accounts.UserNotifier
  alias PlantAid.Alerts
  alias PlantAid.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => id}, attempt: 1}) do
    user = Accounts.get_user!(id)
    Accounts.schedule_email_digest_job(user)
    send_email_digest(user)
    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => id}}) do
    user = Accounts.get_user!(id)
    send_email_digest(user)
    :ok
  end

  def send_email_digest(user) do
    flop = %Flop{
      filters: [
        %Flop.Filter{field: :inserted_at, op: :>=, value: user.notifications_settings.last_run}
      ],
      limit: nil
    }

    now = DateTime.utc_now()
    {alerts, meta} = Alerts.list_alerts(user, flop)

    if meta.total_count > 0 do
      UserNotifier.deliver_alerts_digest(
        user,
        alerts,
        meta.total_count,
        url(~p"/alerts"),
        url(~p"/users/settings")
      )
    end

    user
    |> Accounts.change_user()
    |> Ecto.Changeset.put_embed(
      :notifications_settings,
      Ecto.Changeset.change(user.notifications_settings, last_run: now)
    )
    |> Repo.update!()
  end
end
