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

  describe "diagnostic_test_results" do
    alias PlantAid.Diagnostics.DiagnosticTestResult

    import PlantAid.DiagnosticsFixtures

    @invalid_attrs %{data: nil, metadata: nil, comments: nil}

    test "list_diagnostic_test_results/0 returns all diagnostic_test_results" do
      diagnostic_test_result = diagnostic_test_result_fixture()
      assert Diagnostics.list_diagnostic_test_results() == [diagnostic_test_result]
    end

    test "get_diagnostic_test_result!/1 returns the diagnostic_test_result with given id" do
      diagnostic_test_result = diagnostic_test_result_fixture()
      assert Diagnostics.get_diagnostic_test_result!(diagnostic_test_result.id) == diagnostic_test_result
    end

    test "create_diagnostic_test_result/1 with valid data creates a diagnostic_test_result" do
      valid_attrs = %{data: %{}, metadata: %{}, comments: "some comments"}

      assert {:ok, %DiagnosticTestResult{} = diagnostic_test_result} = Diagnostics.create_diagnostic_test_result(valid_attrs)
      assert diagnostic_test_result.data == %{}
      assert diagnostic_test_result.metadata == %{}
      assert diagnostic_test_result.comments == "some comments"
    end

    test "create_diagnostic_test_result/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Diagnostics.create_diagnostic_test_result(@invalid_attrs)
    end

    test "update_diagnostic_test_result/2 with valid data updates the diagnostic_test_result" do
      diagnostic_test_result = diagnostic_test_result_fixture()
      update_attrs = %{data: %{}, metadata: %{}, comments: "some updated comments"}

      assert {:ok, %DiagnosticTestResult{} = diagnostic_test_result} = Diagnostics.update_diagnostic_test_result(diagnostic_test_result, update_attrs)
      assert diagnostic_test_result.data == %{}
      assert diagnostic_test_result.metadata == %{}
      assert diagnostic_test_result.comments == "some updated comments"
    end

    test "update_diagnostic_test_result/2 with invalid data returns error changeset" do
      diagnostic_test_result = diagnostic_test_result_fixture()
      assert {:error, %Ecto.Changeset{}} = Diagnostics.update_diagnostic_test_result(diagnostic_test_result, @invalid_attrs)
      assert diagnostic_test_result == Diagnostics.get_diagnostic_test_result!(diagnostic_test_result.id)
    end

    test "delete_diagnostic_test_result/1 deletes the diagnostic_test_result" do
      diagnostic_test_result = diagnostic_test_result_fixture()
      assert {:ok, %DiagnosticTestResult{}} = Diagnostics.delete_diagnostic_test_result(diagnostic_test_result)
      assert_raise Ecto.NoResultsError, fn -> Diagnostics.get_diagnostic_test_result!(diagnostic_test_result.id) end
    end

    test "change_diagnostic_test_result/1 returns a diagnostic_test_result changeset" do
      diagnostic_test_result = diagnostic_test_result_fixture()
      assert %Ecto.Changeset{} = Diagnostics.change_diagnostic_test_result(diagnostic_test_result)
    end
  end
end
