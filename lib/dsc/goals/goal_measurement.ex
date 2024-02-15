defmodule DriversSeatCoop.Goals.GoalMeasurement do
  use Ecto.Schema
  import Ecto.Changeset

  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Goals.Goal

  @required_fields ~w(window_date performance_amount performance_percent)a
  @optional_fields ~w(additional_info)a

  schema "goal_measurements" do
    field :performance_amount, :integer
    field :performance_percent, :decimal
    field :window_date, :date
    field :additional_info, :map
    belongs_to(:goal, Goal)
    belongs_to(:user, User)
    timestamps()
  end

  def changeset(goal_measurement, attrs) do
    goal_measurement
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:goal)
  end
end
