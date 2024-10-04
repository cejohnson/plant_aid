defmodule PlantAid.Accounts.UserNotifier do
  import Swoosh.Email

  alias PlantAid.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"PlantAid", "noreply@plant-aid.org"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to accept an invite.
  """
  def deliver_invite_instructions(user, invited_by, url) do
    inviter =
      if invited_by.name && invited_by.name |> String.trim() |> String.length() > 0,
        do: String.trim(invited_by.name),
        else: invited_by.email

    deliver(user.email, "#{inviter} has invited you to Plant Aid", """

    ==============================

    Hi #{user.email},

    #{inviter} has invited you to use Plant Aid, a platform for submitting and viewing plant pathogen observations.

    You can finish setting up your account by visiting the URL below:

    #{url}

    If you don't know #{inviter}, please ignore this.

    ==============================
    """)
  end

  def deliver_alert(user, pathology, observation, alert_url, alert_settings_url) do
    deliver(user.email, "PlantAid Alert: #{pathology.common_name}", """

    ==============================

    Hi #{user.email},

    An observation of #{pathology.common_name} reported on #{observation.observation_date} in #{observation.location} has been confirmed.

    You can view this alert by visiting the URL below:

    #{alert_url}

    You can change your alert settings by visiting the URL below:

    #{alert_settings_url}

    ==============================
    """)
  end

  def deliver_test_result(user, event, observation_url, test_result_url) do
    {event_type_subject, event_type_body} =
      case event do
        "created" ->
          {"New", "a new"}

        "updated" ->
          {"Updated", "an updated"}
      end

    deliver(user.email, "PlantAid: #{event_type_subject} Test Result", """

    ==============================

    Hi #{user.email},

    There is #{event_type_body} test result available for the following observation you submitted:

    #{observation_url}

    You can view the test result by visiting the URL below:

    #{test_result_url}

    ==============================
    """)
  end

  def deliver_alerts_digest(user, alerts, count, alerts_url, alert_settings_url) do
    alert_descriptions =
      alerts
      |> Enum.map(&get_alert_description(&1, alerts_url))
      |> Enum.join("\n")

    deliver(user.email, "PlantAid: You have #{count} new alerts", """

    ==============================

    Hi #{user.email},

    You have #{count} new alerts:

    #{alert_descriptions}

    You can view your alerts by visiting the URL below:

    #{alerts_url}

    You can change your notification settings by visiting the URL below:

    #{alert_settings_url}

    ==============================
    """)
  end

  def get_alert_description(alert, alerts_url) do
    alert_type =
      case alert.alert_type do
        :disease_reported ->
          "Reported"

        :disease_confirmed ->
          "Confirmed"
      end

    "- #{alert_type} instance of #{alert.pathology.common_name} in #{PlantAid.Geography.pretty_print(alert.observation.secondary_subdivision)}: #{alerts_url}/#{alert.id}"
  end
end
