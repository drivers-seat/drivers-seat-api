defmodule DriversSeatCoop.Expenses do
  @moduledoc """
  The Expenses context.
  """
  import Ecto.Query, warn: false
  alias DriversSeatCoop.Expenses.Expense
  alias DriversSeatCoop.Repo

  @non_deductible_expense_categories [
    "Gas",
    "Service"
  ]

  def create_expense(attrs, user_id) do
    %Expense{user_id: user_id}
    |> Expense.changeset(attrs)
    |> Repo.insert()
  end

  def get_expense!(id), do: Repo.get!(Expense, id)

  def update_expense(expense, attrs) do
    expense
    |> Expense.changeset(attrs)
    |> Repo.update()
  end

  def delete_expense(expense) do
    Repo.delete(expense)
  end

  def list_expenses_by_user_id(user_id, opts \\ %{}) do
    limit = Map.get(opts, :limit)
    max_date = Map.get(opts, :max_date)
    since_date = Map.get(opts, :since_date)

    query = from(e in Expense, where: e.user_id == ^user_id, order_by: [desc: :date])

    query =
      if limit do
        from(e in query, limit: ^limit)
      else
        query
      end

    query =
      if max_date do
        from(e in query, where: e.date <= ^max_date)
      else
        query
      end

    if since_date do
      from(e in query, where: e.date >= ^since_date)
    else
      query
    end
    |> Repo.all()
  end

  def is_non_deductible_category(category) do
    Enum.member?(@non_deductible_expense_categories, category)
  end

  def get_total_expenses(user_id, date_start, date_end) do
    qry =
      query_expenses()
      |> query_expenses_filter_user(user_id)
      |> query_expenses_filter_date_range(date_start, date_end)

    from(
      e in qry,
      select: sum(fragment("?::integer", e.money))
    )
    |> Repo.one()
    |> case do
      # if no expenses exist then nil is returned, correct that to zero
      nil -> 0
      res -> res
    end
  end

  def get_total_deductible_expenses(user_id, date_start, date_end) do
    qry =
      query_expenses()
      |> query_expenses_filter_user(user_id)
      |> query_expenses_filter_date_range(date_start, date_end)
      |> query_expenses_categories(false, @non_deductible_expense_categories)

    from(
      e in qry,
      select: sum(fragment("?::integer", e.money))
    )
    |> Repo.one()
    |> case do
      # if no expenses exist then nil is returned, correct that to zero
      nil -> 0
      res -> res
    end
  end

  def query_expenses, do: from(e in Expense)

  def query_expenses_filter_user(qry, user_id_or_ids) do
    user_id_or_ids = List.wrap(user_id_or_ids)
    where(qry, [e], e.user_id in ^user_id_or_ids)
  end

  def query_expenses_filter_date_range(query, date_start, date_end) do
    from(e in query,
      where: fragment("? BETWEEN ? AND ?", e.date, ^date_start, ^date_end)
    )
  end

  def query_expenses_categories(query, include, category_or_categories) do
    category_or_categories = List.wrap(category_or_categories)

    if include do
      from(e in query,
        where: e.category in ^category_or_categories
      )
    else
      from(e in query,
        where: e.category not in ^category_or_categories
      )
    end
  end

  def get_expense_date_range(user_id) do
    query_expenses()
    |> query_expenses_filter_user(user_id)
    |> select([exp], [min(exp.date), max(exp.date)])
    |> Repo.one()
  end

  @doc """
  For a user, identify the years in which they have timespans recorded
  """
  def get_expense_years(user_id) do
    query_expenses()
    |> query_expenses_filter_user(user_id)
    |> select([exp], fragment("DISTINCT DATE_PART('year', ?)::int", exp.date))
    |> Repo.all()
  end
end
