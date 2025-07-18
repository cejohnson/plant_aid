defmodule ConvertSamplesToTestResults do
  import Ecto.Query
  alias PlantAid.DiagnosticTests.TestResult
  alias PlantAid.Repo
  alias PlantAid.Observations.Sample
  alias PlantAid.DiagnosticTests
  alias PlantAid.DiagnosticMethods
  alias PlantAid.Accounts

  def run do
    # TODO: change
    user = Accounts.get_user_by_email("superuser@example.com")

    {:ok, usa_blight_diagnostic_method} =
      DiagnosticMethods.create_diagnostic_method(user, %{
        "name" => "USA Blight Legacy",
        "description" => "A diagnostic method with fields matching the data from USA Blight.",
        "fields" => %{
          "0" => %{
            "_persistent_id" => "0",
            "description" => "",
            "name" => "mating_type",
            "per_pathology" => "false",
            "type" => "string"
          },
          "1" => %{
            "_persistent_id" => "1",
            "description" => "",
            "name" => "gpi",
            "per_pathology" => "false",
            "type" => "string"
          },
          "10" => %{
            "_persistent_id" => "10",
            "description" => "",
            "name" => "pi70",
            "per_pathology" => "false",
            "type" => "string"
          },
          "11" => %{
            "_persistent_id" => "11",
            "description" => "",
            "name" => "pi56",
            "per_pathology" => "false",
            "type" => "string"
          },
          "12" => %{
            "_persistent_id" => "12",
            "description" => "",
            "name" => "pi63",
            "per_pathology" => "false",
            "type" => "string"
          },
          "13" => %{
            "_persistent_id" => "13",
            "description" => "",
            "name" => "d13",
            "per_pathology" => "false",
            "type" => "string"
          },
          "14" => %{
            "_persistent_id" => "14",
            "description" => "",
            "name" => "pi16",
            "per_pathology" => "false",
            "type" => "string"
          },
          "15" => %{
            "_persistent_id" => "15",
            "description" => "",
            "name" => "pi33",
            "per_pathology" => "false",
            "type" => "string"
          },
          "2" => %{
            "_persistent_id" => "2",
            "description" => "",
            "name" => "pep",
            "per_pathology" => "false",
            "type" => "string"
          },
          "3" => %{
            "_persistent_id" => "3",
            "description" => "",
            "name" => "mef",
            "per_pathology" => "false",
            "type" => "string"
          },
          "4" => %{
            "_persistent_id" => "4",
            "description" => "",
            "name" => "rg",
            "per_pathology" => "false",
            "type" => "string"
          },
          "5" => %{
            "_persistent_id" => "5",
            "description" => "",
            "name" => "pi02",
            "per_pathology" => "false",
            "type" => "string"
          },
          "6" => %{
            "_persistent_id" => "6",
            "description" => "",
            "name" => "pi89",
            "per_pathology" => "false",
            "type" => "string"
          },
          "7" => %{
            "_persistent_id" => "7",
            "description" => "",
            "name" => "pi4b",
            "per_pathology" => "false",
            "type" => "string"
          },
          "8" => %{
            "_persistent_id" => "8",
            "description" => "",
            "name" => "pig11",
            "per_pathology" => "false",
            "type" => "string"
          },
          "9" => %{
            "_persistent_id" => "9",
            "description" => "",
            "name" => "pi04",
            "per_pathology" => "false",
            "type" => "string"
          }
        },
        "fields_drop" => [""],
        "fields_sort" => ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
        "11", "12", "13", "14", "15"],
        "pathology_ids" => ["1"]
      })

    users = %{
      "ajs32" => Accounts.get_user_by_email("ajs32@cornell.edu"),
      "wef1" => Accounts.get_user_by_email("wef1@cornell.edu"),
      "msharri2" => Accounts.get_user_by_email("msharri2@ncsu.edu"),
      "asaville" => Accounts.get_user_by_email("acsavill@ncsu.edu")
    }

    samples =
      from(
        s in Sample
      )
      |> Repo.all()

    Enum.each(samples, fn sample ->
      username = sample.metadata["usa_blight"]["updated_by"]
      user = Map.get(users, username)

      test_result = %TestResult{
        inserted_by: user,
        inserted_at: DateTime.from_naive!(sample.inserted_at, "Etc/UTC"),
        updated_by: user,
        updated_at: DateTime.from_naive!(sample.updated_at, "Etc/UTC")
      }

      overrides = DiagnosticTests.get_diagnostic_method_overrides(usa_blight_diagnostic_method.id)

      params = %{
        "observation_id" => Integer.to_string(sample.observation_id),
        "pathology_results" => %{
          "0" => %{
            "_persistent_id" => "0",
            # "pathology_id" => sample.pathology_id && Integer.to_string(sample.pathology_id),
            "genotype_id" => sample.genotype_id && Integer.to_string(sample.genotype_id),
            "result" => sample.result && Atom.to_string(sample.result)}
        },
        "comments" => sample.comments,
        "diagnostic_method_id" => Integer.to_string(usa_blight_diagnostic_method.id),
        "fields" => %{
          "0" => %{"_persistent_id" => "0", "name" => "mating_type", "value" => get_field_value(sample.metadata["usa_blight"]["mating_type"])},
          "1" => %{"_persistent_id" => "1", "name" => "gpi", "value" => get_field_value(sample.metadata["usa_blight"]["gpi"])},
          "2" => %{"_persistent_id" => "2", "name" => "pep", "value" => get_field_value(sample.metadata["usa_blight"]["pep"])},
          "3" => %{"_persistent_id" => "3", "name" => "mef", "value" => get_field_value(sample.metadata["usa_blight"]["mef"])},
          "4" => %{"_persistent_id" => "4", "name" => "rg", "value" => get_field_value(sample.metadata["usa_blight"]["rg"])},
          "5" => %{"_persistent_id" => "5", "name" => "pi02", "value" => get_field_value(sample.metadata["usa_blight"]["pi02"])},
          "6" => %{"_persistent_id" => "6", "name" => "pi89", "value" => get_field_value(sample.metadata["usa_blight"]["pi89"])},
          "7" => %{"_persistent_id" => "7", "name" => "pi4b", "value" => get_field_value(sample.metadata["usa_blight"]["pi4b"])},
          "8" => %{"_persistent_id" => "8", "name" => "pig11", "value" => get_field_value(sample.metadata["usa_blight"]["pig11"])},
          "9" => %{"_persistent_id" => "9", "name" => "pi04", "value" => get_field_value(sample.metadata["usa_blight"]["pi04"])},
          "10" => %{"_persistent_id" => "10", "name" => "pi70", "value" => get_field_value(sample.metadata["usa_blight"]["pi70"])},
          "11" => %{"_persistent_id" => "11", "name" => "pi56", "value" => get_field_value(sample.metadata["usa_blight"]["pi56"])},
          "12" => %{"_persistent_id" => "12", "name" => "pi63", "value" => get_field_value(sample.metadata["usa_blight"]["pi63"])},
          "13" => %{"_persistent_id" => "13", "name" => "d13", "value" => get_field_value(sample.metadata["usa_blight"]["d13"])},
          "14" => %{"_persistent_id" => "14", "name" => "pi16", "value" => get_field_value(sample.metadata["usa_blight"]["pi16"])},
          "15" => %{"_persistent_id" => "15", "name" => "pi33", "value" => get_field_value(sample.metadata["usa_blight"]["pi33"])}
        }
      }

      changeset = DiagnosticTests.change_test_result(test_result, overrides, params)
      Repo.insert(changeset)
    end)
  end

  defp get_field_value("NULL"), do: ""
  defp get_field_value(value), do: value
end

ConvertSamplesToTestResults.run
