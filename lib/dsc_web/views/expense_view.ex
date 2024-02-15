defmodule DriversSeatCoopWeb.ExpenseView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.ExpenseView

  def render("index.json", %{expenses: expenses}) do
    %{data: render_many(expenses, ExpenseView, "expense.json")}
  end

  def render("show.json", %{expense: expense}) do
    %{data: render_one(expense, ExpenseView, "expense.json")}
  end

  def render("expense.json", %{expense: expense}) do
    %{
      id: expense.id,
      category: expense.category,
      date: expense.date,
      money: expense.money,
      name: expense.name,
      user_id: expense.user_id
    }
  end
end
