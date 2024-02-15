defmodule DriversSeatCoop.Shifts.Shift do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(start_time)a
  @optional_fields ~w(end_time frontend_mileage deleted)a

  schema "shifts" do
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :frontend_mileage, :float
    field :deleted, :boolean, default: false

    belongs_to :user, DriversSeatCoop.Accounts.User
    belongs_to :device, DriversSeatCoop.Devices.Device

    timestamps()
  end

  @doc false
  def changeset(shift, attrs) do
    shift
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:device)
  end
end
