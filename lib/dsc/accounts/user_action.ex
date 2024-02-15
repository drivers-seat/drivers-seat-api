defmodule DriversSeatCoop.Accounts.UserAction do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(event recorded_at user_id)a
  @optional_fields ~w()a

  schema "user_actions" do
    field :recorded_at, :naive_datetime
    field :event, :string

    belongs_to :user, DriversSeatCoop.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(user_action, attrs) do
    user_action
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
  end
end
