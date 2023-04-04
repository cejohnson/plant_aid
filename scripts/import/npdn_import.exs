alias NimbleCSV.RFC4180, as: CSV
alias PlantAid.Repo
alias PlantAid.Geography
alias PlantAid.Hosts
alias PlantAid.LocationTypes
alias PlantAid.Pathologies
alias PlantAid.Observations.Observation

[folder | []] = System.argv()
IO.puts("Importing NPDN data from #{folder}")

hosts = Hosts.list_hosts()
tomato = Enum.find(hosts, fn h ->
  h.common_name == "Tomato"
end)
potato = Enum.find(hosts, fn h ->
  h.common_name == "Potato"
end)

pathologies = Pathologies.list_pathologies()
late_blight = Enum.find(pathologies, fn p ->
  p.common_name == "Late Blight"
end)

location_types = LocationTypes.list_location_types()
potato_seed = Enum.find(location_types, fn l ->
  l.name == "Potato seed"
end)

countries = Geography.list_countries()
united_states = Enum.find(countries, fn c ->
  c.name == "United States of America"
end)

primary_subdivisions = Geography.list_primary_subdivisions()
|> Repo.preload(:secondary_subdivisions)

secondary_subdivisions = Geography.list_secondary_subdivisions()
|> Repo.preload(:primary_subdivision)

timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

observations =
  (folder <> "/NPDNlateblight archive.csv")
  |> File.read!()
  |> CSV.parse_string()
  |> Enum.map(fn [
    sample_date,
    observation_date,
    diagnostic_lab,
    sample_id,
    diagnosis_number,
    pest_code,
    pest_common_name,
    pest_scientific_name,
    overall_confidence,
    host_code,
    host_common_name,
    host_scientific_name,
    fips_code,
    county,
    state,
    zip_code,
    lab_method,
    _,
    _,
    _,
    _
  ] ->
    %{
      sample_date: sample_date,
      observation_date: observation_date,
      diagnostic_lab: diagnostic_lab,
      sample_id: sample_id,
      diagnosis_number: diagnosis_number,
      pest_code: pest_code,
      pest_common_name: pest_common_name,
      pest_scientific_name: pest_scientific_name,
      overall_confidence: overall_confidence,
      host_code: host_code,
      host_common_name: host_common_name,
      host_scientific_name: host_scientific_name,
      fips_code: fips_code,
      county: county,
      state: state,
      zip_code: zip_code,
      lab_method: lab_method
    }
  end)

obs = observations
|> Enum.map(fn o ->
  {:ok, {y, m, d}} = Calendar.ISO.parse_date(o.sample_date, :basic)
  {:ok, sample_date} = Date.new(y, m, d)

  {:ok, observation_date} = case Calendar.ISO.parse_date(o.observation_date, :basic) do
    {:ok, {y, m, d}} ->
      Date.new(y, m, d)
    {:error, _} ->
      {:ok, sample_date}
  end

  host = case o.host_code do
    "11005" ->
      tomato
    c when c in ["14013", "14100"] ->
      potato
    _ ->
      nil
  end

  host_other = case host do
    nil ->
      o.host_common_name
    _ ->
      nil
  end

  location_type = case o.host_code do
    "14100" ->
      potato_seed
    _ ->
      nil
  end

  secondary_subdivision = Enum.find(secondary_subdivisions, fn s ->
    fips_code = String.pad_leading(o.fips_code, 5, "0")
    s.primary_subdivision.country_id == united_states.id
    && String.ends_with?(fips_code, s.metadata["FIPS"])
    && String.starts_with?("US" <> fips_code, s.primary_subdivision.metadata["FIPS"])
    # s.metadata["FIPS"] == o.fips_code
  end)

  unless secondary_subdivision do
    IO.inspect(o, label: "no FIPS code found")
  end

  %{
    status: :submitted,
    source: :npdn,
    observation_date: observation_date,
    suspected_pathology_id: late_blight.id,
    host_id: host && host.id,
    host_other: host_other,
    location_type_id: location_type && location_type.id,
    country_id: united_states.id,
    primary_subdivision_id: secondary_subdivision.primary_subdivision_id,
    secondary_subdivision_id: secondary_subdivision.id,
    inserted_at: timestamp,
    updated_at: timestamp,
    metadata: %{
      npdn: o
    }
  }
end)

IO.inspect(length(obs), label: "obs to insert")
IO.inspect(List.first(obs), label: "example")

{count, observations} = Repo.insert_all(Observation, obs, returning: [:id])
IO.puts("Inserted #{count} observations")


observations =
  (folder <> "/npdn_data_request_ristaino_20230123.csv")
  |> File.read!()
  |> CSV.parse_string()
  |> Enum.map(fn [
    record_id,
    county,
    host_common_name,
    lab_method,
    pest_common_name,
    pest_scientific_name,
    sample_date,
    state
  ] ->
    %{
      record_id: record_id,
      county: county,
      host_common_name: host_common_name,
      lab_method: lab_method,
      pest_common_name: pest_common_name,
      pest_scientific_name: pest_scientific_name,
      sample_date: sample_date,
      state: state
    }
  end)

  obs = observations |> Enum.map(fn o ->
    [y, m, d] = String.split(o.sample_date, "-") |> Enum.map(&String.to_integer(&1))
    observation_date = case Date.new(y, m, d) do
      {:ok, observation_date} ->
        observation_date
      {:error, :invalid_date} ->
        nil
    end

    {host, host_other} = case o.host_common_name do
      "Tomato" ->
        {tomato, nil}
      "Potato" ->
        {potato, nil}
      name ->
        {nil, name}
    end

    location_type = case o.host_common_name do
      "Potato (Seed)" ->
        potato_seed
      _ ->
        nil
    end

    [county, state] = String.split(o.county, ", ")
    county = case county do
      "De Kalb" ->
        "DeKalb"
      _ ->
        county
    end

    primary_subdivision = Enum.find(primary_subdivisions, fn p ->
      p.country_id == united_states.id
      && p.iso3166_2 == "US-#{state}"
    end)

    secondary_subdivision = Enum.find(primary_subdivision.secondary_subdivisions, fn s ->
      String.contains?(county, s.name)
      || String.jaro_distance(s.name, county) > 0.9
    end)

    %{
      status: :submitted,
      source: :npdn,
      observation_date: observation_date,
      suspected_pathology_id: late_blight.id,
      host_id: host && host.id,
      host_other: host_other,
      country_id: united_states.id,
      primary_subdivision_id: primary_subdivision.id,
      secondary_subdivision_id: secondary_subdivision && secondary_subdivision.id,
      inserted_at: timestamp,
      updated_at: timestamp,
      metadata: %{
        npdn: o
      }
    }
  end)

  IO.inspect(length(obs), label: "obs to insert")
  IO.inspect(List.first(obs), label: "example")

{count, observations} = Repo.insert_all(Observation, obs, returning: [:id])
IO.puts("Inserted #{count} observations")
