defmodule DriversSeatCoop.GigAccounts.UserGigAccount do
  use Ecto.Schema
  import Ecto.Changeset

  alias DriversSeatCoop.Accounts.User

  @required_fields ~w(
    argyle_id
    employer
    account_data)a

  @optional_fields ~w(
    is_connected
    connection_status
    connection_error_code
    connection_error_message
    connection_updated_at
    connection_has_errors
    is_synced
    activity_status
    activity_count
    activities_updated_at
    activity_date_min
    activity_date_max
    deleted)a

  schema "user_gig_accounts" do
    field :argyle_id, :string
    field :employer, :string

    field :is_connected, :boolean, default: false
    field :connection_has_errors, :boolean, default: false
    field :connection_status, :string
    field :connection_error_code, :string
    field :connection_error_message, :string
    field :connection_updated_at, :utc_datetime

    field :is_synced, :boolean, default: false
    field :activity_status, :string
    field :activity_count, :integer
    field :activities_updated_at, :utc_datetime
    field :activity_date_min, :utc_datetime
    field :activity_date_max, :utc_datetime

    field :deleted, :boolean, default: false
    field :account_data, :map

    belongs_to(:user, User)

    timestamps()
  end

  def changeset(gig_account, attrs) do
    gig_account
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
    |> unique_constraint([:argyle_id], name: :user_gig_accounts_argyle_id)
  end
end
