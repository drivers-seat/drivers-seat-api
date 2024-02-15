defmodule DriversSeatCoop.Research.FocusGroupMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(enroll_date)a
  @optional_fields ~w(unenroll_date)a

  schema "focus_group_memberships" do
    field :enroll_date, :utc_datetime
    field :unenroll_date, :utc_datetime
    belongs_to :user, DriversSeatCoop.Accounts.User

    belongs_to :research_group, DriversSeatCoop.Research.ResearchGroup,
      foreign_key: :focus_group_id

    timestamps()
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:research_group)
    |> unique_constraint([:user_id, :focus_group_id, :enroll_date],
      name: :focus_group_memberships_ak
    )
  end
end
