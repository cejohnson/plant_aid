defmodule PlantAid.Hosts do
  @moduledoc """
  The Hosts context.
  """
  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias PlantAid.Repo

  alias PlantAid.Accounts.User
  alias PlantAid.Hosts.Host

  def authorize(:list_hosts, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:create_host, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:get_host, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:update_host, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:delete_host, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  @doc """
  Returns the list of hosts.

  ## Examples

      iex> list_hosts()
      [%Host{}, ...]

  """
  def list_hosts do
    Repo.all(Host) |> Repo.preload(:varieties)
  end

  @doc """
  Gets a single host.

  Raises `Ecto.NoResultsError` if the Host does not exist.

  ## Examples

      iex> get_host!(123)
      %Host{}

      iex> get_host!(456)
      ** (Ecto.NoResultsError)

  """
  def get_host!(id), do: Repo.get!(Host, id) |> Repo.preload(:varieties)

  @doc """
  Creates a host.

  ## Examples

      iex> create_host(%{field: value})
      {:ok, %Host{}}

      iex> create_host(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_host(attrs \\ %{}) do
    %Host{}
    |> Host.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a host.

  ## Examples

      iex> update_host(host, %{field: new_value})
      {:ok, %Host{}}

      iex> update_host(host, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_host(%Host{} = host, attrs) do
    host
    |> Host.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a host.

  ## Examples

      iex> delete_host(host)
      {:ok, %Host{}}

      iex> delete_host(host)
      {:error, %Ecto.Changeset{}}

  """
  def delete_host(%Host{} = host) do
    Repo.delete(host)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking host changes.

  ## Examples

      iex> change_host(host)
      %Ecto.Changeset{data: %Host{}}

  """
  def change_host(%Host{} = host, attrs \\ %{}) do
    Host.changeset(host, attrs)
  end

  alias PlantAid.Hosts.HostVariety

  # @doc """
  # Returns the list of host_varieties.

  # ## Examples

  #     iex> list_host_varieties()
  #     [%HostVariety{}, ...]

  # """
  # def list_host_varieties do
  #   Repo.all(HostVariety)
  # end

  # @doc """
  # Gets a single host_variety.

  # Raises `Ecto.NoResultsError` if the Host variety does not exist.

  # ## Examples

  #     iex> get_host_variety!(123)
  #     %HostVariety{}

  #     iex> get_host_variety!(456)
  #     ** (Ecto.NoResultsError)

  # """
  # def get_host_variety!(id), do: Repo.get!(HostVariety, id)

  # @doc """
  # Creates a host_variety.

  # ## Examples

  #     iex> create_host_variety(%{field: value})
  #     {:ok, %HostVariety{}}

  #     iex> create_host_variety(%{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def create_host_variety(attrs \\ %{}) do
  #   %HostVariety{}
  #   |> HostVariety.changeset(attrs)
  #   |> Repo.insert()
  # end

  # @doc """
  # Updates a host_variety.

  # ## Examples

  #     iex> update_host_variety(host_variety, %{field: new_value})
  #     {:ok, %HostVariety{}}

  #     iex> update_host_variety(host_variety, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def update_host_variety(%HostVariety{} = host_variety, attrs) do
  #   host_variety
  #   |> HostVariety.changeset(attrs)
  #   |> Repo.update()
  # end

  # @doc """
  # Deletes a host_variety.

  # ## Examples

  #     iex> delete_host_variety(host_variety)
  #     {:ok, %HostVariety{}}

  #     iex> delete_host_variety(host_variety)
  #     {:error, %Ecto.Changeset{}}

  # """
  # def delete_host_variety(%HostVariety{} = host_variety) do
  #   Repo.delete(host_variety)
  # end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking host_variety changes.

  ## Examples

      iex> change_host_variety(host_variety)
      %Ecto.Changeset{data: %HostVariety{}}

  """
  def change_host_variety(%HostVariety{} = host_variety, attrs \\ %{}) do
    HostVariety.changeset(host_variety, attrs)
  end
end
