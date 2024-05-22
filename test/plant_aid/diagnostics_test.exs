defmodule PlantAid.DiagnosticsTest do
  use PlantAid.DataCase

  alias PlantAid.Diagnostics

  describe "diagnostic_methods" do
    alias PlantAid.Diagnostics.DiagnosticMethod

    import PlantAid.DiagnosticsFixtures

    @invalid_attrs %{name: nil}

    test "list_diagnostic_methods/0 returns all diagnostic_methods" do
      diagnostic_method = diagnostic_method_fixture()
      assert Diagnostics.list_diagnostic_methods() == [diagnostic_method]
    end

    test "get_diagnostic_method!/1 returns the diagnostic_method with given id" do
      diagnostic_method = diagnostic_method_fixture()
      assert Diagnostics.get_diagnostic_method!(diagnostic_method.id) == diagnostic_method
    end

    test "create_diagnostic_method/1 with valid data creates a diagnostic_method" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %DiagnosticMethod{} = diagnostic_method} = Diagnostics.create_diagnostic_method(valid_attrs)
      assert diagnostic_method.name == "some name"
    end

    test "create_diagnostic_method/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Diagnostics.create_diagnostic_method(@invalid_attrs)
    end

    test "update_diagnostic_method/2 with valid data updates the diagnostic_method" do
      diagnostic_method = diagnostic_method_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %DiagnosticMethod{} = diagnostic_method} = Diagnostics.update_diagnostic_method(diagnostic_method, update_attrs)
      assert diagnostic_method.name == "some updated name"
    end

    test "update_diagnostic_method/2 with invalid data returns error changeset" do
      diagnostic_method = diagnostic_method_fixture()
      assert {:error, %Ecto.Changeset{}} = Diagnostics.update_diagnostic_method(diagnostic_method, @invalid_attrs)
      assert diagnostic_method == Diagnostics.get_diagnostic_method!(diagnostic_method.id)
    end

    test "delete_diagnostic_method/1 deletes the diagnostic_method" do
      diagnostic_method = diagnostic_method_fixture()
      assert {:ok, %DiagnosticMethod{}} = Diagnostics.delete_diagnostic_method(diagnostic_method)
      assert_raise Ecto.NoResultsError, fn -> Diagnostics.get_diagnostic_method!(diagnostic_method.id) end
    end

    test "change_diagnostic_method/1 returns a diagnostic_method changeset" do
      diagnostic_method = diagnostic_method_fixture()
      assert %Ecto.Changeset{} = Diagnostics.change_diagnostic_method(diagnostic_method)
    end
  end
end
