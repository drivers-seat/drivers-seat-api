defmodule DriversSeatCoopWeb.MarketingValidator do
  alias Ecto.Changeset

  def present_accept_or_decline(params) do
    types = %{
      campaign: :string,
      action_id: :string,
      additional_data: :map
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:campaign])

    changeset =
      changeset
      |> Changeset.put_change(
        :additional_data,
        Changeset.get_change(changeset, :additional_data, %{})
      )

    Changeset.apply_action(changeset, :insert)
  end

  def postpone(params) do
    types = %{
      campaign: :string,
      action_id: :string,
      postpone_minutes: :integer,
      additional_data: :map
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:campaign])

    changeset =
      changeset
      |> Changeset.put_change(
        :additional_data,
        Changeset.get_change(changeset, :additional_data, %{})
      )

    Changeset.apply_action(changeset, :insert)
  end

  def save_campaign_state(params) do
    types = %{
      campaign: :string,
      additional_data: :map
    }

    data = %{}

    changeset =
      {data, types}
      |> Changeset.cast(params, Map.keys(types))
      |> Changeset.validate_required([:campaign])

    changeset =
      changeset
      |> Changeset.put_change(
        :additional_data,
        Changeset.get_change(changeset, :additional_data, %{})
      )

    Changeset.apply_action(changeset, :insert)
  end
end
