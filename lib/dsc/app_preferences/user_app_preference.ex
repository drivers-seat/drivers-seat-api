defmodule DriversSeatCoop.AppPreferences.UserAppPreference do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(user_id key value last_updated_device_id last_updated_app_version)a

  schema "user_app_preferences" do
    field :key, :string
    field :value, :map
    field :last_updated_device_id, :string
    field :last_updated_app_version, :string

    belongs_to :user, DriversSeatCoop.Accounts.User

    timestamps()
  end

  def changeset(user_app_preference, attrs) do
    user_app_preference
    |> cast(attrs, @required_fields)
    |> unique_constraint([:user_id, :key], name: :user_app_preferences_user_key)
    |> assoc_constraint(:user)
  end
end
