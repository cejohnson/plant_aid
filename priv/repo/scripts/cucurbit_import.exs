alias NimbleCSV.RFC4180, as: CSV
alias PlantAid.Repo
alias PlantAid.Geography
alias PlantAid.Hosts
alias PlantAid.Hosts.Host
alias PlantAid.LocationTypes
alias PlantAid.Pathologies
alias PlantAid.Observations.Observation

[folder | []] = System.argv()
IO.puts("Importing NPDN data from #{folder}")

# hosts = Hosts.list_hosts()
# tomato = Enum.find(hosts, fn h ->
#   h.common_name == "Tomato"
# end)
# potato = Enum.find(hosts, fn h ->
#   h.common_name == "Potato"
# end)

# pathologies = Pathologies.list_pathologies()
# late_blight = Enum.find(pathologies, fn p ->
#   p.common_name == "Late Blight"
# end)

# location_types = LocationTypes.list_location_types()
# potato_seed = Enum.find(location_types, fn l ->
#   l.name == "Potato seed"
# end)

countries = Geography.list_countries()
united_states = Enum.find(countries, fn c ->
  c.name == "United States of America"
end)

primary_subdivisions = Geography.list_primary_subdivisions()
|> Repo.preload(:secondary_subdivisions)

# secondary_subdivisions = Geography.list_secondary_subdivisions()
# |> Repo.preload(:primary_subdivision)

timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

hosts = [
  "Cucumber",
  "Squash",
  "Cantaloupe",
  "Pumpkin",
  "Watermelon"
]
|> Enum.map(fn h ->
  %{
    common_name: h,
    inserted_at: timestamp,
    updated_at: timestamp
  }
end)

{count, hosts} = Repo.insert_all(Host, hosts, returning: [:common_name, :id])

{:ok, cdm} = Pathologies.create_pathology(%{common_name: "Cucurbit Downy Mildew", scientific_name: "Pseudoperonospora cubensis"})
IO.inspect(cdm, label: "cdm")

[2008, 2009, 2010, 2011]
|> Enum.each(fn year ->
observations =
  (folder <> "/#{year}_cdm_reports.csv")
  |> File.read!()
  |> CSV.parse_string()
  |> Enum.map(fn [
    symptom_day_of_year,
    host,
    month,
    week,
    state,
    county,
    lat,
    long
  ] ->
    %{
      symptom_date_day_of_year: symptom_day_of_year,
      host: host,
      month: month,
      week: week,
      state: state,
      county: county,
      latitude: lat,
      longitude: long,
    }
  end)

obs = observations
|> Enum.map(fn o ->
  # This is so dumb but it's not worth doing it better
  {:ok, observation_date} = Enum.find_value(1..12, fn m ->
    Enum.find_value(1..31, fn d ->
      doy = try do
        Calendar.ISO.day_of_year(year, m, d)
      rescue
        ArgumentError ->
          nil
      end

      if doy == String.to_integer(o.symptom_date_day_of_year) do
        Date.new(year, m, d)
      end
    end)
  end)

  # Mostly because "watermel" is a thing
  host = Enum.find(hosts, fn h ->
    String.jaro_distance(h.common_name, o.host) > 0.9
  end)

  primary_subdivision = Enum.find(primary_subdivisions, fn p ->
    p.country_id == united_states.id
    && p.iso3166_2 == "US-#{o.state}"
  end)

  county = String.trim(o.county)
  county = case county do
    "Miami" ->
      "Miami-Dade"
    "EBaton Rouge" ->
      "East Baton Rouge"
    "Ebaton_Rouge" ->
      "East Baton Rouge"
    c ->
      c
  end

  secondary_subdivision = Enum.find(primary_subdivision.secondary_subdivisions, fn s ->
    String.contains?(county, s.name)
    || String.contains?(s.name, county)
    || String.jaro_distance(s.name, county) > 0.85
  end)

  unless secondary_subdivision do
    IO.inspect(o, label: "no FIPS code found")
  end

  position = %Geo.Point{
    coordinates: {String.to_float(o.longitude), String.to_float(o.latitude)},
    srid: 4326
  }
    # if is_float(elem(Float.parse(o.lat), 0)) && elem(Float.parse(o.lat), 0) != 0 &&
    #      is_float(elem(Float.parse(o.lon), 0)) && elem(Float.parse(o.lon), 0) != 0 do
    #   %Geo.Point{
    #     coordinates: {String.to_float(o.lon), String.to_float(o.lat)},
    #     srid: 4326
    #   }
    # end

  %{
    status: :submitted,
    source: :cucurbit_sentinel_network,
    observation_date: observation_date,
    suspected_pathology_id: cdm.id,
    host_id: host.id,
    country_id: united_states.id,
    primary_subdivision_id: primary_subdivision.id,
    secondary_subdivision_id: secondary_subdivision.id,
    position: position,
    inserted_at: timestamp,
    updated_at: timestamp,
    metadata: %{
      cucurbit_sentinel_network: o
    }
  }
end)

IO.inspect(length(obs), label: "obs to insert")
IO.inspect(List.first(obs), label: "example")

{count, observations} = Repo.insert_all(Observation, obs, returning: [:id])
IO.puts("Inserted #{count} observations")
end)
