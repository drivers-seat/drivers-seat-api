defmodule DriversSeatCoop.ReferralSource do
  use Ecto.Schema
  import Ecto.Changeset

  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.ReferralType

  @required_fields ~w(referral_type referral_code is_active)a
  @optional_fields ~w(user_id)a

  schema "referral_sources" do
    field :referral_type, ReferralType
    field :referral_code, :string
    field :is_active, :boolean, default: true

    belongs_to(:user, User)

    timestamps()
  end

  def changeset(expense, attrs) do
    expense
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:referral_code,
      name: :referral_sources_index_code,
      message: "Referral Code Already Exists"
    )
    |> unique_constraint([:user_id, :referral_type], name: :referral_sources_type_user)
    |> assoc_constraint(:user)
  end
end
