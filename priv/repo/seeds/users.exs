alias PlantAid.Accounts.User
alias PlantAid.Repo

# Obviously this is only to be used in dev
password = Argon2.hash_pwd_salt("password")
timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

users = [
  %{
    email: "superuser@example.com",
    hashed_password: password,
    roles: [:superuser],
    inserted_at: timestamp,
    updated_at: timestamp
  },
  %{
    email: "admin@example.com",
    hashed_password: password,
    roles: [:admin],
    inserted_at: timestamp,
    updated_at: timestamp
  },
  %{
    email: "researcher@example.com",
    hashed_password: password,
    roles: [:researcher],
    inserted_at: timestamp,
    updated_at: timestamp
  },
  %{
    email: "user@example.com",
    hashed_password: password,
    roles: [],
    inserted_at: timestamp,
    updated_at: timestamp
  }
]

Repo.insert_all(User, users)
