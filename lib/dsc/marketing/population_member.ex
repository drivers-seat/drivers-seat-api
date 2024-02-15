defmodule DriversSeatCoop.Marketing.PopulationMember do
  use Ecto.Schema
  import Ecto.Changeset
  alias DriversSeatCoop.Accounts.User

  @required_fields ~w(user_id population_type population)a
  @optional_fields ~w(additional_data)a

  schema "population_members" do
    field :population_type, :string
    field :population, :string
    field :additional_data, :map

    belongs_to(:user, User)

    timestamps()
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :population_type, :population], name: :population_members_key)
    |> assoc_constraint(:user)
  end
end
