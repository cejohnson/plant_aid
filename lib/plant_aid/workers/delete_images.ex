defmodule PlantAid.Workers.DeleteImages do
  require Logger
  use Oban.Worker

  alias PlantAid.ObjectStorage

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"urls" => urls}}) do
    ObjectStorage.delete_objects(urls)
    :ok
  end
end
