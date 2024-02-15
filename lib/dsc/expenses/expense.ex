defmodule DriversSeatCoop.Expenses.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  alias DriversSeatCoop.Accounts.User

  @required_fields ~w(category date money name)a
  @optional_fields ~w()a

  schema "expenses" do
    field :category, :string
    field :name, :string
    field :date, :date
    field :money, :float

    belongs_to(:user, User)

    timestamps()
  end

  def changeset(expense, attrs) do
    expense
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
  end
end
