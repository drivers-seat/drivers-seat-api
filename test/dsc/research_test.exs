defmodule DriversSeatCoop.ResearchTest do
  use DriversSeatCoop.DataCase

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Research

  describe "research_groups" do
    alias DriversSeatCoop.Research.ResearchGroup

    @valid_attrs %{description: "some description", name: "some name", code: "some code"}
    @update_attrs %{
      description: "some updated description",
      name: "some updated name",
      code: "some updated code"
    }
    @invalid_attrs %{description: nil, name: nil, code: nil}

    def research_group_fixture(attrs \\ %{}) do
      {:ok, research_group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Research.create_research_group()

      research_group
    end

    test "list_research_groups/0 returns all research_groups" do
      research_group = Factory.create_research_group()
      assert Research.list_research_groups() == [research_group]
    end

    test "get_research_group!/1 returns the research_group with given id" do
      research_group = Factory.create_research_group()
      assert Research.get_research_group!(research_group.id) == research_group
    end

    test "get_research_group_by_case_insensitive_code/1 returns a research_group" do
      %{id: id} = Factory.create_research_group(code: "TEST")
      _research_group = Factory.create_research_group(code: "TEST1")

      assert %ResearchGroup{id: ^id} =
               Research.get_research_group_by_case_insensitive_code("Test")
    end

    test "create_research_group/1 with valid data creates a research_group" do
      assert {:ok, %ResearchGroup{} = research_group} =
               Research.create_research_group(@valid_attrs)

      assert research_group.description == "some description"
      assert research_group.name == "some name"
    end

    test "create_research_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Research.create_research_group(@invalid_attrs)
    end

    test "update_research_group/2 with valid data updates the research_group" do
      research_group = Factory.create_research_group()

      assert {:ok, %ResearchGroup{} = research_group} =
               Research.update_research_group(research_group, @update_attrs)

      assert research_group.description == "some updated description"
      assert research_group.name == "some updated name"
    end

    test "update_research_group/2 with invalid data returns error changeset" do
      research_group = Factory.create_research_group()

      assert {:error, %Ecto.Changeset{}} =
               Research.update_research_group(research_group, @invalid_attrs)

      assert research_group == Research.get_research_group!(research_group.id)
    end

    test "delete_research_group/1 deletes the research_group" do
      research_group = Factory.create_research_group()
      assert {:ok, %ResearchGroup{}} = Research.delete_research_group(research_group)
      assert_raise Ecto.NoResultsError, fn -> Research.get_research_group!(research_group.id) end
    end

    test "change_research_group/1 returns a research_group changeset" do
      research_group = Factory.create_research_group()
      assert %Ecto.Changeset{} = Research.change_research_group(research_group)
    end

    test "Adding research group membership to user, adds to audit table" do
      research_group = Factory.create_research_group()
      user = Factory.create_user()

      {:ok, user} =
        Accounts.update_user(user, %{
          focus_group: research_group.code
        })

      membership = Research.get_current_membership(user.id)

      assert user.focus_group == research_group.code
      assert membership != nil
      assert membership.focus_group_id == research_group.id
    end

    test "Updating user without setting membership does not affect history" do
      research_group = Factory.create_research_group()
      user = Factory.create_user()

      {:ok, user} =
        Accounts.update_user(user, %{
          focus_group: research_group.code
        })

      membership = Research.get_current_membership(user.id)

      assert user.focus_group == research_group.code
      assert membership != nil
      assert membership.focus_group_id == research_group.id

      {:ok, user} = Accounts.update_user(user, %{last_name: "test"})

      membership = Research.get_current_membership(user.id)

      assert user.focus_group == research_group.code
      assert membership != nil
      assert membership.focus_group_id == research_group.id
    end

    test "Removing user from research group, records end_date in audit table" do
      research_group = Factory.create_research_group()
      user = Factory.create_user()

      {:ok, user} =
        Accounts.update_user(user, %{
          focus_group: research_group.code
        })

      membership = Research.get_current_membership(user.id)

      assert user.focus_group == research_group.code
      assert membership != nil
      assert membership.focus_group_id == research_group.id

      {:ok, user} =
        Accounts.update_user(user, %{
          focus_group: nil
        })

      membership = Research.get_current_membership(user.id)

      assert user.focus_group == nil
      assert membership == nil
    end

    test "Replacing focus group with a new one unenrolls from original group" do
      research_group_1 =
        Factory.create_research_group(%{
          code: "TEST1"
        })

      research_group_2 =
        Factory.create_research_group(%{
          code: "TEST2"
        })

      user = Factory.create_user()

      {:ok, user} =
        Accounts.update_user(user, %{
          focus_group: "test1"
        })

      # test membership
      membership = Research.get_current_membership(user.id)

      assert user.focus_group == "test1"
      assert membership != nil
      assert membership.focus_group_id == research_group_1.id

      # enroll in second group, should enroll from first
      {:ok, user} =
        Accounts.update_user(user, %{
          focus_group: "test2"
        })

      membership = Research.get_current_membership(user.id)

      assert user.focus_group == "test2"
      assert membership != nil
      assert membership.focus_group_id == research_group_2.id

      # enroll from second, should result in no enrollments
      {:ok, user} =
        Accounts.update_user(user, %{
          focus_group: nil
        })

      membership = Research.get_current_membership(user.id)
      assert user.focus_group == nil
      assert membership == nil
    end
  end
end
