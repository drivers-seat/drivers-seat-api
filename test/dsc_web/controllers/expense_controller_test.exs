defmodule DriversSeatCoopWeb.ExpenseControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true

  alias DriversSeatCoop.Expenses.Expense

  @create_attrs %{
    category: "Gas",
    name: "Name",
    money: 10.99,
    date: Date.utc_today()
  }
  @update_attrs %{
    category: "Tools",
    name: "updated name",
    money: 20.99
  }
  @invalid_attrs %{
    category: nil,
    name: nil,
    money: nil
  }

  setup %{conn: conn} do
    user = Factory.create_user()

    conn =
      put_req_header(conn, "accept", "application/json")
      |> TestHelpers.put_auth_header(user)

    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all expenses for user", %{conn: conn, user: user} do
      %Expense{id: expense_id} = Factory.create_expense(%{user_id: user.id})
      conn = get(conn, Routes.expense_path(conn, :index))
      assert [%{"id" => ^expense_id}] = json_response(conn, 200)["data"]
    end

    test "lists all expenses within date range for user", %{conn: conn, user: user} do
      %Expense{id: expense_id} = Factory.create_expense(%{user_id: user.id, date: "2021-01-02"})

      %Expense{id: expense2_id} = Factory.create_expense(%{user_id: user.id, date: "2020-12-31"})

      conn =
        get(conn, Routes.expense_path(conn, :index), %{
          since_date: "2021-01-01",
          max_date: "2021-01-05"
        })

      assert [%{"id" => ^expense_id}] = json_response(conn, 200)["data"]

      assert_raise MatchError, fn ->
        [%{"id" => ^expense2_id}] = json_response(conn, 200)["data"]
      end
    end
  end

  describe "create" do
    test "renders expense with valid attributes", %{conn: conn} do
      conn = post(conn, Routes.expense_path(conn, :create), expense: @create_attrs)
      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end

    test "renders error when creating with invalid attributes", %{conn: conn} do
      conn = post(conn, Routes.expense_path(conn, :create), expense: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update" do
    test "renders updated expense", %{conn: conn, user: user} do
      %Expense{id: expense_id} = Factory.create_expense(%{user_id: user.id})

      conn = put(conn, Routes.expense_path(conn, :update, expense_id), expense: @update_attrs)

      assert %{"id" => ^expense_id} = json_response(conn, 200)["data"]
    end

    test "renders error when updating with invalid attributes", %{conn: conn, user: user} do
      %Expense{id: expense_id} = Factory.create_expense(%{user_id: user.id})

      assert_raise MatchError, fn ->
        put(conn, Routes.expense_path(conn, :update, expense_id), expense: @invalid_attrs)
      end
    end
  end

  describe "delete" do
    test "deletes expense", %{conn: conn, user: user} do
      %Expense{id: expense_id} = Factory.create_expense(%{user_id: user.id})

      conn = delete(conn, Routes.expense_path(conn, :delete, expense_id))

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, Routes.expense_path(conn, :show, expense_id))
      end
    end
  end
end
