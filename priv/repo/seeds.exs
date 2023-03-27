# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PlantAid.Repo.insert!(%PlantAid.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias NimbleCSV.RFC4180, as: CSV

alias PlantAid.Geography.{
  Country,
  PrimarySubdivision,
  SecondarySubdivision
}

alias PlantAid.Repo

# Geography
countries =
  [
    {"United States of America", "US", "USA", "840"},
    {"Canada", "CA", "CAN", "124"},
    {"Mexico", "MX", "MEX", "484"}
  ]
  |> Enum.map(fn {name, iso3166_1_alpha2, iso3166_1_alpha3, iso3166_1_numeric} ->
    %{
      name: name,
      iso3166_1_alpha2: iso3166_1_alpha2,
      iso3166_1_alpha3: iso3166_1_alpha3,
      iso3166_1_numeric: iso3166_1_numeric,
      metadata: %{
        "FIPS country code" => iso3166_1_alpha2
      }
    }
  end)

{count, countries} =
  Repo.insert_all(Country, countries, returning: [:id, :name, :iso3166_1_alpha2])

IO.puts("Inserted #{count} countries")
IO.inspect(List.first(countries), label: "Example")

# United States
country = Enum.find(countries, fn c -> c.iso3166_1_alpha2 == "US" end)

primary_subdivisions =
  Path.expand("priv/repo/data/geography/us.csv")
  |> File.read!()
  |> CSV.parse_string()
  |> Enum.map(fn [code, name, category, fips] ->
    %{
      name: name,
      category: category,
      iso3166_2: code,
      metadata: %{
        "FIPS" => fips
      },
      country_id: country.id
    }
  end)

{count, primary_subdivisions} =
  Repo.insert_all(PrimarySubdivision, primary_subdivisions,
    returning: [:id, :name, :iso3166_2, :country_id]
  )

IO.puts("Inserted #{count} primary_subdivisions")
IO.inspect(List.first(primary_subdivisions), label: "Example")

secondary_subdivisions =
  "priv/repo/data/geography/us.geojson"
  |> File.read!()
  |> Jason.decode!()
  |> (fn json -> json["features"] end).()
  |> Enum.map(fn feature ->
    props = feature["properties"]

    primary_subdivision =
      Enum.find(primary_subdivisions, fn ps -> String.contains?(ps.iso3166_2, props["STUSPS"]) end)

    if primary_subdivision == nil do
      raise "No state found for #{props["STUSPS"]}"
    end

    %{
      name: props["NAME"],
      category: String.split(props["NAMELSAD"]) |> List.last(),
      geog: Geo.JSON.decode!(feature["geometry"]),
      metadata: %{
        "FIPS" => props["COUNTYFP"],
        "GEOID" => props["GEOID"],
        "LSAD" => props["LSAD"],
        "COUNTYNS" => props["COUNTYNS"],
        "ALAND" => props["ALAND"],
        "AWATER" => props["AWATER"]
      },
      primary_subdivision_id: primary_subdivision.id
    }
  end)

{count, secondary_subdivisions} =
  Repo.insert_all(SecondarySubdivision, secondary_subdivisions, returning: [:id, :name])

IO.puts("Inserted #{count} secondary_subdivisions")
IO.inspect(List.first(secondary_subdivisions), label: "Example")

# Canada
country = Enum.find(countries, fn c -> c.iso3166_1_alpha2 == "CA" end)

primary_subdivisions =
  Path.expand("priv/repo/data/geography/ca.csv")
  |> File.read!()
  |> CSV.parse_string()
  |> Enum.map(fn [code, name, category, fips, sgc] ->
    %{
      name: name,
      category: category,
      iso3166_2: code,
      metadata: %{
        "FIPS" => fips,
        "PRUID" => sgc
      },
      country_id: country.id
    }
  end)

{count, primary_subdivisions} =
  Repo.insert_all(PrimarySubdivision, primary_subdivisions,
    returning: [:id, :name, :iso3166_2, :metadata, :country_id]
  )

IO.puts("Inserted #{count} primary_subdivisions")
IO.inspect(List.first(primary_subdivisions), label: "Example")

cdtypes_to_descriptions = %{
  "CDR" => "Census division",
  "CT" => "County",
  "CTY" => "County",
  "DIS" => "District",
  "DM" => "District municipality",
  "MRC" => "Municipalité régionale de comté",
  "RD" => "Regional district",
  "REG" => "Region",
  "RM" => "Regional municipality",
  "TÉ" => "Territoire équivalent",
  "TER" => "Territory",
  "UC" => "United counties"
}

secondary_subdivisions =
  "priv/repo/data/geography/ca.geojson"
  |> File.read!()
  |> Jason.decode!()
  |> (fn json -> json["features"] end).()
  |> Enum.map(fn feature ->
    props = feature["properties"]

    primary_subdivision =
      Enum.find(primary_subdivisions, fn psd -> psd.metadata["PRUID"] == props["PRUID"] end)

    if primary_subdivision == nil do
      raise "No province found for #{props["PRUID"]}"
    end

    %{
      name: props["CDNAME"],
      category: Map.get(cdtypes_to_descriptions, props["CDTYPE"]),
      geog: Geo.JSON.decode!(feature["geometry"]),
      metadata: %{
        "CDUID" => props["CDUID"],
        "DGUID" => props["DGUID"],
        "ALAND" => props["LANDAREA"]
      },
      primary_subdivision_id: primary_subdivision.id
    }
  end)

{count, secondary_subdivisions} =
  Repo.insert_all(SecondarySubdivision, secondary_subdivisions, returning: [:id, :name])

IO.puts("Inserted #{count} secondary_subdivisions")
IO.inspect(List.first(secondary_subdivisions), label: "Example")

# Mexico
country = Enum.find(countries, fn c -> c.iso3166_1_alpha2 == "MX" end)

primary_subdivisions =
  Path.expand("priv/repo/data/geography/mx.csv")
  |> File.read!()
  |> CSV.parse_string()
  |> Enum.map(fn [code, name, category, fips, inegi] ->
    %{
      name: name,
      category: category,
      iso3166_2: code,
      metadata: %{
        "FIPS" => fips,
        "INEGI" => inegi
      },
      country_id: country.id
    }
  end)

{count, primary_subdivisions} =
  Repo.insert_all(PrimarySubdivision, primary_subdivisions,
    returning: [:id, :name, :iso3166_2, :metadata, :country_id]
  )

IO.puts("Inserted #{count} primary_subdivisions")
IO.inspect(List.first(primary_subdivisions), label: "Example")

secondary_subdivisions =
  "priv/repo/data/geography/mx.geojson"
  |> File.read!()
  |> Jason.decode!()
  |> (fn json -> json["features"] end).()
  |> Enum.map(fn feature ->
    props = feature["properties"]

    primary_subdivision =
      Enum.find(primary_subdivisions, fn psd -> psd.metadata["INEGI"] == props["CVE_ENT"] end)

    if primary_subdivision == nil do
      raise "No province found for #{props["CVE_ENT"]}"
    end

    %{
      name: props["NOM_MUN"],
      category: "Municipality",
      geog: Geo.JSON.decode!(feature["geometry"]),
      metadata: %{
        "INEGI" => props["CVE_MUN"],
        "ALAND" => props["Area"]
      },
      primary_subdivision_id: primary_subdivision.id
    }
  end)

{count, secondary_subdivisions} =
  Repo.insert_all(SecondarySubdivision, secondary_subdivisions, returning: [:id, :name])

IO.puts("Inserted #{count} secondary_subdivisions")
IO.inspect(List.first(secondary_subdivisions), label: "Example")
