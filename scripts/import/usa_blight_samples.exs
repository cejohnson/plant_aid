# Usage: mix run scripts/usa_blight_import.exs <folder>

import Ecto.Query
import Geo.PostGIS

alias PlantAid.Observations
alias NimbleCSV.RFC4180, as: CSV
alias PlantAid.Repo
alias PlantAid.Pathologies
alias PlantAid.Pathologies.Genotype
alias PlantAid.Pathologies.Pathology
alias PlantAid.Observations.Observation
alias PlantAid.Observations.Sample


[folder | []] = System.argv()
IO.puts("Importing USA Blight data from #{folder}")

timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

pathology = Repo.get_by!(Pathology, common_name: "Late Blight")
IO.inspect(pathology, label: "pathology")

samples =
  (folder <> "/lateblight_table_samples.csv")
  |> File.read!()
  |> CSV.parse_string()
  # |> Enum.random()
  # |> (fn s ->
  #   [s]
  # end).()
  |> Enum.map(fn [submitted,
                  id,
                  obs_id,
                  active,
                  user,
                  received,
                  mating_type,
                  gpi,
                  pep,
                  mef,
                  rg,
                  genotype,
                  pi02,
                  pi89,
                  pi4b,
                  pig11,
                  pi04,
                  pi70,
                  pi56,
                  pi63,
                  d13,
                  pi16,
                  pi33,
                  updated,
                  updated_by,
                  comments] ->
    %{
      submitted: submitted,
      id: id,
      obs_id: obs_id,
      active: active,
      user: user,
      received: received,
      mating_type: mating_type,
      gpi: gpi,
      pep: pep,
      mef: mef,
      rg: rg,
      genotype: genotype,
      pi02: pi02,
      pi89: pi89,
      pi4b: pi4b,
      pig11: pig11,
      pi04: pi04,
      pi70: pi70,
      pi56: pi56,
      pi63: pi63,
      d13: d13,
      pi16: pi16,
      pi33: pi33,
      updated: updated,
      updated_by: updated_by,
      comments: comments
    }
  end)
  |> Enum.map(fn s ->
    data = s
      |> Map.drop([:submitted, :id, :obs_id, :active, :user, :received, :updated, :updated_by, :comments, :genotype])
      |> Enum.reject(fn {_k, v} ->
        is_nil(v) || v == "NULL"
      end)
      |> Enum.map(fn {k, v} ->
        %PlantAid.Observations.Sample.KeyValuePair{
          id: Ecto.UUID.generate(),
          key: k,
          value: v
        }
      end)

    observation_id = from(
      o in Observation,
      where: fragment(~s|metadata @> '{"usa_blight":{"id":?}}'|, literal(^s.obs_id)),
      select: o.id
    )
    |> Repo.one()

    if observation_id do
      genotype_name = case Regex.run(~r/(US-\d+)/, s.genotype, capture: :first) do
        nil ->
          nil
        [name] ->
          name
      end

      genotype_id = case genotype_name do
        nil ->
          nil
        name ->
          genotype = Repo.get_by(Genotype, name: name)
          if is_nil(genotype) do
            {:ok, genotype} = Pathologies.create_genotype(pathology.id, %{"name" => name})
            genotype.id
          else
            genotype.id
          end
      end

      # end
      #   nil ->
      #     nil
      #   "NULL" ->
      #     nil
      #   ~r/US-\d+^\?/ ->
      #     nil

      # end


      # genotype_id = if not is_nil(s.genotype) && s.genotype != "NULL" do
      #   cond do

      #   end
      #   genotype = Repo.get_by(Genotype, name: s.genotype)
      #   if is_nil(genotype) do
      #     {:ok, genotype} = Pathologies.create_genotype(pathology.id, %{"name" => s.genotype})
      #     genotype.id
      #   else
      #     genotype.id
      #   end
      # else
      #   nil
      # end

      {:ok, inserted_at} = NaiveDateTime.from_iso8601(s.submitted)
      updated_at = case NaiveDateTime.from_iso8601(s.updated) do
        {:ok, updated_at} ->
          updated_at
        {:error, _} ->
          inserted_at
      end

      %{
        result: :positive,
        confidence: 0.95,
        comments: s.comments,
        metadata: %{usa_blight: s},
        data: data,
        observation_id: observation_id,
        pathology_id: pathology.id,
        genotype_id: genotype_id,
        inserted_at: inserted_at,
        updated_at: updated_at
      }
    else
      nil
    end
  end)
  |> Enum.reject(fn s -> is_nil(s) end)
  |> Enum.uniq_by(fn %{observation_id: id} -> id end)

IO.puts("Inserting #{length(samples)} samples")
IO.inspect(List.first(samples), label: "Example")

{count, samples} = Repo.insert_all(Sample, samples, returning: [:id, :metadata])
IO.puts("Inserted #{count} observations")
