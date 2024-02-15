defmodule DriversSeatCoopWeb.ReferralSourceValidator do
  alias DriversSeatCoop.ReferralType
  alias Ecto.Changeset

  def show(params) do
    types = %{
      referral_type: ReferralType
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:referral_type])

    Changeset.apply_action(changeset, :insert)
  end
end
