defmodule DriversSeatCoop.Marketing.CampaignState do
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Devices.Device
  alias DriversSeatCoop.Marketing.CampaignParticipant
  alias DriversSeatCoop.Marketing.CampaignState

  @enforce_keys [
    :user,
    :device,
    :participant
  ]
  defstruct [
    :user,
    :device,
    :participant
  ]

  def new(%User{} = user, %Device{} = device, %CampaignParticipant{} = participant) do
    %CampaignState{
      user: user,
      device: device,
      participant: participant
    }
  end
end
