defmodule DriversSeatCoop.Goals.Goal do
  use Ecto.Schema
  import Ecto.Changeset

  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Goals.GoalFrequency
  alias DriversSeatCoop.Goals.GoalType

  @required_fields ~w(type frequency start_date amount sub_frequency)a
  @optional_fields ~w()a

  schema "goals" do
    field :type, GoalType
    field :frequency, GoalFrequency
    field :sub_frequency, :string, default: "all"
    field :start_date, :date
    field :amount, :integer
    belongs_to(:user, User)
    timestamps()
  end

  def changeset(goal, attrs) do
    goal
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
    |> unique_constraint([:user, :type, :frequency, :start_date, :sub_frequency],
      name: :goals_unique_key
    )
  end
end
