defmodule DriversSeatCoop.Marketing.CampaignParticipant do
  use Ecto.Schema
  import Ecto.Changeset
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Marketing.CampaignParticipant

  @required_fields ~w(user_id campaign)a
  @optional_fields ~w(presented_on_first presented_on_last dismissed_on dismissed_action accepted_on accepted_action postponed_until postponed_action additional_data)a

  schema "campaign_participants" do
    field :campaign, :string
    field :presented_on_first, :utc_datetime
    field :presented_on_last, :utc_datetime
    field :dismissed_on, :utc_datetime
    field :dismissed_action, :string
    field :accepted_on, :utc_datetime
    field :accepted_action, :string
    field :postponed_until, :utc_datetime
    field :postponed_action, :string
    field :additional_data, :map

    belongs_to(:user, User)

    timestamps()
  end

  def changeset(participant, %CampaignParticipant{} = attrs) do
    changeset(participant, Map.from_struct(attrs))
  end

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :campaign], name: :campaign_participants_user_campaign_key)
    |> assoc_constraint(:user)
  end

  def get_status_info(nil = _participant), do: %{status: status(nil)}

  def get_status_info(%CampaignParticipant{} = participant) do
    status_info =
      participant
      |> Map.take([:accepted_on, :dismissed_on, :postponed_until])
      |> Map.put(:status, status(participant))
      |> Map.put(:presented_on, participant.presented_on_last)
      |> Map.put(:state, participant.additional_data)

    if Map.get(status_info, :status) != :postponed do
      Map.put(status_info, :postponed_until, nil)
    else
      status_info
    end
  end

  def status(nil), do: :new

  def status(%CampaignParticipant{} = participant) do
    cond do
      not is_nil(participant.dismissed_on) ->
        :dismissed

      not is_nil(participant.accepted_on) ->
        :accepted

      not is_nil(participant.postponed_until) and
          DateTime.compare(DateTime.utc_now(), participant.postponed_until) == :lt ->
        :postponed

      not is_nil(participant.presented_on_first) ->
        :presented

      true ->
        :new
    end
  end
end
