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
end
