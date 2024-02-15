defmodule DriversSeatCoopWeb.ExpenseController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Expenses
  alias DriversSeatCoop.Expenses.Expense
  alias DriversSeatCoop.Expenses.Oban.ExportUserExpensesQuery

  plug DriversSeatCoopWeb.AuthenticationPlug
  action_fallback DriversSeatCoopWeb.FallbackController

  def index(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.ExpenseValidator.index(params) do
      expenses = Expenses.list_expenses_by_user_id(conn.assigns.user.id, params)
      render(conn, "index.json", expenses: expenses)
    end
  end

  def create(conn, %{"expense" => expense_params}) do
    with {:ok, %Expense{} = expense} <-
           Expenses.create_expense(expense_params, conn.assigns.user.id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.expense_path(conn, :create))
      |> render("show.json", expense: expense)
    end
  end

  def show(conn, %{"id" => id}) do
    expense = Expenses.get_expense!(id)

    with :ok <- DriversSeatCoop.Authorizer.authorize(:show, expense, conn.assigns.user) do
      render(conn, "show.json", expense: expense)
    end
  end

  def update(conn, %{"id" => id, "expense" => expense_params}) do
    expense = Expenses.get_expense!(id)

    with :ok <- DriversSeatCoop.Authorizer.authorize(:update, expense, conn.assigns.user) do
      {:ok, %Expense{} = updated_expense} = Expenses.update_expense(expense, expense_params)
      render(conn, "show.json", expense: updated_expense)
    end
  end

  def delete(conn, %{"id" => id}) do
    expense = Expenses.get_expense!(id)

    with :ok <- DriversSeatCoop.Authorizer.authorize(:update, expense, conn.assigns.user) do
      {:ok, expense} = Expenses.delete_expense(expense)
      render(conn, "show.json", expense: expense)
    end
  end

  def export(conn, %{"query" => params}) do
    with {:ok, params} <- DriversSeatCoopWeb.ExpenseValidator.export(params) do
      user = conn.assigns.user

      with {:ok, _} <-
             ExportUserExpensesQuery.schedule_job(user.id, params) do
        send_resp(conn, :no_content, "")
      end
    end
  end
end
