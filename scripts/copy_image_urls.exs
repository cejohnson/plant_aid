import Ecto.Changeset
import Ecto.Query
alias PlantAid.Repo
alias PlantAid.Observations.Observation

from(
  o in Observation,
  where: fragment("array_length(?, 1) > 0", o.image_urls)
)
|> Repo.all()
|> Enum.each(fn observation ->
  images = Enum.map(observation.image_urls, &%{"url" => &1})

  observation
  |> cast(%{"images" => images}, [])
  |> cast_embed(:images, with: fn images, attrs ->
    images
    |> cast(attrs, [:url])
  end)
  |> Repo.update!()
end)
