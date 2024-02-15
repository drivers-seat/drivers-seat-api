defmodule DriversSeatCoop.Accounts.UserServiceIdentifier do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_services [
    "mixpanel",
    "onesignal"
  ]

  @required_fields ~w(
    user_id
    service
    identifiers
  )a

  schema "user_service_identifiers" do
    field :service, :string
    field :identifiers, {:array, :string}
    belongs_to :user, DriversSeatCoop.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(user_service_identifiers, attrs) do
    user_service_identifiers
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:service, @valid_services)
    |> assoc_constraint(:user)
  end
end
