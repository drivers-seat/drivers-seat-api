defmodule DriversSeatCoop.Repo.Migrations.TrackUserMarketingCampaignParticipation do
  use Ecto.Migration

  def change do
    create table(:campaign_participants) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:campaign, :citext, null: false)
      add(:presented_on_first, :utc_datetime)
      add(:presented_on_last, :utc_datetime)
      add(:dismissed_on, :utc_datetime)
      add(:dismissed_action, :citext)
      add(:accepted_on, :utc_datetime)
      add(:accepted_action, :citext)
      add(:postponed_until, :utc_datetime)
      add(:postponed_action, :citext)
      add(:additional_data, :map)
      timestamps()
    end

    create unique_index(:campaign_participants, [:user_id, :campaign],
             name: :campaign_participants_user_campaign_key
           )
  end
end
