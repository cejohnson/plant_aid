defmodule PlantAid.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  @timestamps_opts [type: :utc_datetime]

  @derive {
    Flop.Schema,
    filterable: [
      :email,
      :name,
      :roles,
      :confirmed_at,
      :last_seen
    ],
    sortable: [
      :email,
      :name,
      :last_seen
    ],
    default_order: %{
      order_by: [:last_seen, :name],
      order_directions: [:desc_nulls_last, :asc_nulls_last]
    },
    adapter_opts: [
      join_fields: [
        last_seen: [
          binding: :last_seen,
          field: :timestamp,
          ecto_type: :utc_datetime
        ]
      ]
    ]
  }

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :invited_at, :utc_datetime
    field :confirmed_at, :utc_datetime
    field :roles, {:array, Ecto.Enum}, values: [:superuser, :admin, :researcher], default: []
    field :name, :string
    field :metadata, :map

    # has_many :connection_events, PlantAid.Accounts.UserConnectionEvent

    field :last_seen, :utc_datetime, virtual: true

    embeds_one :notifications_settings, NotificationsSettings do
      field :enabled, :boolean, default: false
      field :utc_hour, :integer
      field :timezone, :string
      field :local_time, :time, virtual: true
    end

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :name])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, PlantAid.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  def notifications_changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> cast_embed(:notifications_settings)
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def name_changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  def accept_invite_changeset(user, attrs, opts \\ []) do
    now = DateTime.utc_now(:second)

    user
    |> cast(attrs, [:password, :name])
    |> validate_password(opts)
    |> put_change(:confirmed_at, now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%PlantAid.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:name, :email, :roles])
    |> validate_email(opts)
  end

  def has_role?(%User{} = user, roles) when is_list(roles) do
    Enum.any?(roles, &has_role?(user, &1))
  end

  def has_role?(%User{} = user, role) when is_atom(role) do
    Enum.member?(user.roles, role)
  end
end
