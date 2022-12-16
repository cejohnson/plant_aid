# Usage: mix run priv/scripts/usa_blight_import.exs <folder>

alias PlantAid.Observations
alias NimbleCSV.RFC4180, as: CSV
alias PlantAid.Repo
alias PlantAid.Accounts.User
alias PlantAid.Hosts.Host
alias PlantAid.LocationTypes.LocationType
alias PlantAid.Pathologies.Pathology
alias PlantAid.Observations.Observation
alias PlantAid.Genomics.Genotype

[folder | []] = System.argv()
IO.puts("Importing USA Blight data from #{folder}")

timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

csv_users =
  (folder <> "/usablight_alert_users - usablight_alert_users.csv")
  |> File.read!()
  |> CSV.parse_string()
  |> Enum.map(fn [email, first_name, last_name] ->
    first_name = String.capitalize(first_name)
    last_name = String.capitalize(last_name)

    %{
      email: String.downcase(email),
      name: first_name <> " " <> last_name,
      preferred_name: first_name,
      inserted_at: timestamp,
      updated_at: timestamp,
      metadata: %{source: "usa_blight"},
      roles: [],
      # No password can ever match this value
      hashed_password: "INVALID"
    }
  end)

{_count, users} = Repo.insert_all(User, csv_users, returning: [:id, :email])
# IO.inspect(count)
# IO.inspect(List.first(users))
emails_to_user_ids =
  users
  |> Enum.map(fn user ->
    {user.email, user.id}
  end)
  |> Enum.into(%{})

# IO.puts("Found #{length(users)} users")
# IO.puts("Example/sanity check:")
# IO.inspect(List.first(users))

csv_hosts =
  (folder <> "/lateblight_table_host.csv")
  |> File.read!()
  |> CSV.parse_string()
  |> Enum.map(fn [code, name, sci_name] ->
    %{
      common_name: name,
      scientific_name: sci_name,
      metadata: %{usa_blight_code: code},
      inserted_at: timestamp,
      updated_at: timestamp
    }
  end)

# IO.inspect(usa_blight_host_ids_to_hosts)
# IO.inspect(plant_aid_hosts)
{_count, hosts} = Repo.insert_all(Host, csv_hosts, returning: [:id, :metadata])

usa_blight_codes_to_host_ids =
  hosts
  |> Enum.map(fn host ->
    {host.metadata["usa_blight_code"], host.id}
  end)
  |> Enum.into(%{})

IO.inspect(usa_blight_codes_to_host_ids, label: "usa_blight_codes_to_host_ids")

csv_location_types =
  (folder <> "/lateblight_table_location_setting.csv")
  |> File.read!()
  |> CSV.parse_string()
  |> Enum.map(fn [code, name, _only_with_type] ->
    organic = String.match?(name, ~r/Organic/)
    [name | _] = String.split(name, " (")
    name = String.trim(name)

    %{
      code: code,
      name: name,
      organic: organic
    }
  end)

plant_aid_location_types =
  csv_location_types
  |> Enum.reduce([], fn location_type, acc ->
    case Enum.find_index(acc, fn lt -> lt.name == location_type.name end) do
      nil ->
        acc ++
          [
            %{
              name: location_type.name,
              metadata: %{
                usa_blight_codes: [location_type.code]
              },
              inserted_at: timestamp,
              updated_at: timestamp
            }
          ]

      index ->
        List.update_at(acc, index, fn lt ->
          put_in(
            lt.metadata.usa_blight_codes,
            lt.metadata.usa_blight_codes ++ [location_type.code]
          )
        end)
    end
  end)

{_count, location_types} =
  Repo.insert_all(LocationType, plant_aid_location_types, returning: [:id, :metadata])

IO.inspect(location_types, label: "location_types")

usa_blight_codes_to_location_types =
  csv_location_types
  |> Enum.map(fn lt ->
    location_type =
      Enum.find(location_types, fn location_type ->
        Enum.member?(location_type.metadata["usa_blight_codes"], lt.code)
      end)

    {lt.code,
     {
       location_type.id,
       lt.organic
     }}
  end)
  |> Enum.into(%{})

IO.inspect(usa_blight_codes_to_location_types, label: "usa_blight_codes_to_location_types")

# IO.inspect(plant_aid_location_types)
# IO.inspect(usa_blight_location_settings)

{:ok, late_blight} =
  Repo.insert(%Pathology{
    common_name: "Late Blight",
    scientific_name: "Phytophthora infestans",
    inserted_at: timestamp,
    updated_at: timestamp
  })

IO.inspect(late_blight, label: "late_blight")

csv_observations =
  (folder <> "/lateblight_table_obs.csv")
  |> File.stream!()
  |> CSV.parse_stream()
  |> Stream.map(fn [
                     id,
                     has_sample,
                     sample_id,
                     received,
                     alert,
                     notify,
                     confirmed,
                     confirmed_changed,
                     confirmed_changed_by,
                     confirmed_changed_email,
                     user,
                     ip,
                     reporter_name,
                     reporter_email,
                     reporter_phone,
                     ob,
                     location_setting,
                     location_other,
                     dm_state,
                     dm_country,
                     dm_county,
                     nearest_landmark,
                     lat,
                     lon,
                     fips,
                     fips_name,
                     host,
                     host_other,
                     presence,
                     percent_infected,
                     leaf_infected,
                     percent,
                     image,
                     image2,
                     image3,
                     image4,
                     image5,
                     control_products_used,
                     narrative_description,
                     confirmer_name,
                     confirmer_email,
                     verification_method,
                     notes,
                     last_edit,
                     last_edit_by
                   ] ->
    %{
      id: id,
      has_sample: has_sample,
      sample_id: sample_id,
      received: received,
      alert: alert,
      notify: notify,
      confirmed: confirmed,
      confirmed_changed: confirmed_changed,
      confirmed_changed_by: confirmed_changed_by,
      confirmed_changed_email: confirmed_changed_email,
      user: user,
      ip: ip,
      reporter_name: reporter_name,
      reporter_email: reporter_email,
      reporter_phone: reporter_phone,
      ob: ob,
      location_setting: location_setting,
      location_other: location_other,
      dm_state: dm_state,
      dm_country: dm_country,
      dm_county: dm_county,
      nearest_landmark: nearest_landmark,
      lat: lat,
      lon: lon,
      fips: fips,
      fips_name: fips_name,
      host: host,
      host_other: host_other,
      presence: presence,
      percent_infected: percent_infected,
      leaf_infected: leaf_infected,
      percent: percent,
      control_products_used: control_products_used,
      narrative_description: narrative_description,
      confirmer_name: confirmer_name,
      confirmer_email: confirmer_email,
      verification_method: verification_method,
      notes: notes,
      last_edit: last_edit,
      last_edit_by: last_edit_by
    }
  end)
  # |> Stream.filter(fn %{confirmer_email: email} ->
  #   Map.has_key?(emails_to_user_ids, String.downcase(email))
  # end)
  |> Stream.filter(fn %{lat: lat, lon: lon} ->
    is_float(elem(Float.parse(lat), 0)) && elem(Float.parse(lat), 0) != 0 &&
      is_float(elem(Float.parse(lon), 0)) && elem(Float.parse(lon), 0) != 0
  end)
  |> Stream.reject(fn %{host: host} ->
    String.length(host) == 0
  end)
  |> Enum.group_by(fn %{host: host} ->
    cond do
      String.contains?(host, ",") ->
        :multi_host

      true ->
        :single_host
    end
  end)

single_host_observations = csv_observations.single_host
multi_host_observations = csv_observations.multi_host

IO.inspect(List.first(single_host_observations, label: "example obs"))
IO.inspect(length(single_host_observations), label: "single host observation count")
IO.inspect(length(multi_host_observations), label: "multi host observation count")

host_frequencies =
  single_host_observations
  |> Enum.frequencies_by(fn %{host: host} ->
    host
  end)

obs =
  multi_host_observations
  |> Enum.map(fn o ->
    host =
      String.split(o.host, ",")
      |> Enum.max_by(fn h ->
        Map.get(host_frequencies, h)
      end)

    %{o | host: host}
  end)
  |> Enum.concat(single_host_observations)
  |> Enum.map(fn o ->
    user_id = Map.get(emails_to_user_ids, String.downcase(o.reporter_email))
    host_id = Map.get(usa_blight_codes_to_host_ids, o.host)

    {location_type_id, organic} =
      Map.fetch!(usa_blight_codes_to_location_types, o.location_setting)

    observation_date =
      o.ob
      |> Date.from_iso8601!()

    inserted_at =
      case NaiveDateTime.from_iso8601(o.received) do
        {:ok, inserted_at} ->
          inserted_at

        {:error, _} ->
          observation_date
      end
      |> DateTime.from_naive!("Etc/UTC")

    updated_at =
      case NaiveDateTime.from_iso8601(o.last_edit) do
        {:ok, updated_at} ->
          updated_at

        {:error, _} ->
          inserted_at
      end
      |> DateTime.from_naive!("Etc/UTC")

    %{
      status: :submitted,
      user_id: user_id,
      control_method: o.control_products_used,
      notes: o.narrative_description,
      host_other: o.host_other,
      organic: organic,
      observation_date: observation_date,
      host_id: host_id,
      location_type_id: location_type_id,
      suspected_pathology_id: late_blight.id,
      position: %Geo.Point{
        coordinates: {String.to_float(o.lon), String.to_float(o.lat)},
        srid: 4326
      },
      inserted_at: inserted_at,
      updated_at: updated_at,
      metadata: %{
        usa_blight: %{
          id: o.id,
          has_sample: o.has_sample,
          sample_id: o.sample_id,
          received: o.received,
          alert: o.alert,
          notify: o.notify,
          confirmed: o.confirmed,
          confirmed_changed: o.confirmed_changed,
          confirmed_changed_by: o.confirmed_changed_by,
          confirmed_changed_email: o.confirmed_changed_email,
          user: o.user,
          ip: o.ip,
          reporter_name: o.reporter_name,
          reporter_email: o.reporter_email,
          reporter_phone: o.reporter_phone,
          ob: o.ob,
          location_setting: o.location_setting,
          location_other: o.location_other,
          dm_state: o.dm_state,
          dm_country: o.dm_country,
          dm_county: o.dm_county,
          nearest_landmark: o.nearest_landmark,
          lat: o.lat,
          lon: o.lon,
          fips: o.fips,
          fips_name: o.fips_name,
          host: o.host,
          host_other: o.host_other,
          presence: o.presence,
          percent_infected: o.percent_infected,
          leaf_infected: o.leaf_infected,
          percent: o.percent,
          control_products_used: o.control_products_used,
          narrative_description: o.narrative_description,
          confirmer_name: o.confirmer_name,
          confirmer_email: o.confirmer_email,
          verification_method: o.verification_method,
          notes: o.notes,
          last_edit: o.last_edit,
          last_edit_by: o.last_edit_by
        }
      }
    }
  end)
  |> Enum.sort(&(&1.observation_date <= &2.observation_date))

{count, observations} = Repo.insert_all(Observation, obs, returning: [:id, :metadata])

IO.inspect(count, label: "insertion count")
IO.inspect(List.first(observations), label: "example observation")

# usa_blight_obs_id_to_id =
#   observations
#   |> Enum.map(fn observation ->
#     {observation.metadata["usa_blight"]["id"], observation.id}
#   end)
#   |> Enum.into(%{})

# csv_genotypes =
#   (folder <> "/lateblight_table_genotype.csv")
#   |> File.read!()
#   |> CSV.parse_string()
#   |> Enum.map(fn [
#                    genotype,
#                    mating_type,
#                    gpi,
#                    pep,
#                    mef,
#                    mtdna,
#                    rg57_band_num,
#                    rg57,
#                    pi02,
#                    pi89,
#                    pi4b,
#                    pig11,
#                    pi04,
#                    pi70,
#                    pi56,
#                    pi63,
#                    d13,
#                    pi16,
#                    pi33
#                  ] ->
#     %{
#       genotype: genotype,
#       mating_type: mating_type,
#       gpi: gpi,
#       pep: pep,
#       pep: pep,
#       mtdna: mtdna,
#       rg57_band_num: rg57_band_num,
#       rg57: rg57,
#       pi02: pi02,
#       pi89: pi89,
#       pi4b: pi4b,
#       pig11: pig11,
#       pi04: pi04,
#       pi70: pi70,
#       pi56: pi56,
#       pi63: pi63,
#       d13: d13,
#       pi16: pi16,
#       pi33: pi33,
#       inserted_at: timestamp,
#       updated_at: timestamp
#     }
#   end)

# Repo.insert_all(Genotype, csv_genotypes)

# csv_samples =
#   (folder <> "/lateblight_table_samples.csv")
#   |> File.stream!()
#   |> CSV.parse_stream()
#   |> Stream.map(fn [
#                      submitted,
#                      id,
#                      obs_id,
#                      active,
#                      user,
#                      received,
#                      mating_type,
#                      gpi,
#                      pep,
#                      mef,
#                      rg,
#                      genotype,
#                      pi02,
#                      pi89,
#                      pi4b,
#                      pig11,
#                      pi04,
#                      pi70,
#                      pi56,
#                      pi63,
#                      d13,
#                      pi16,
#                      pi33,
#                      updated,
#                      updated_by,
#                      comments
#                    ] ->
#     inserted_at =
#       case NaiveDateTime.from_iso8601(submitted) do
#         {:ok, inserted_at} ->
#           inserted_at

#         {:error, _} ->
#           timestamp
#       end
#       |> DateTime.from_naive!("Etc/UTC")

#     updated_at =
#       case NaiveDateTime.from_iso8601(updated) do
#         {:ok, updated_at} ->
#           updated_at

#         {:error, _} ->
#           inserted_at
#       end
#       |> DateTime.from_naive!("Etc/UTC")

#     %{
#       submitted: submitted,
#       id: id,
#       obs_id: obs_id,
#       active: active,
#       user: user,
#       received: received,
#       mating_type: mating_type,
#       gpi: gpi,
#       pep: pep,
#       mef: mef,
#       rg: rg,
#       genotype: genotype,
#       pi02: pi02,
#       pi89: pi89,
#       pi4b: pi4b,
#       pig11: pig11,
#       pi04: pi04,
#       pi70: pi70,
#       pi56: pi56,
#       pi63: pi63,
#       d13: d13,
#       pi16: pi16,
#       pi33: pi33,
#       updated: updated,
#       updated_by: updated_by,
#       comments: comments,
#       inserted_at: inserted_at,
#       updated_at: updated_at
#     }
#   end)

# add_to_database? =
#   case IO.gets("Add users to database? [y/[n]] ") |> String.downcase() |> String.trim() do
#     "y" ->
#       true

#     "yes" ->
#       true

#     _ ->
#       false
#   end

# if add_to_database? do
#   IO.puts("Adding users to database")
#   Repo.insert_all(User, users)
#   IO.puts("Users added")
# else
#   IO.puts("Exiting")
# end
