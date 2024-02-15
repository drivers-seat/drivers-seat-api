defmodule DriversSeatCoop.Repo.Migrations.TrackReferrals do
  use Ecto.Migration
  alias DriversSeatCoop.ReferralType

  def change do
    ReferralType.create_type()

    create table(:referral_sources) do
      add(:user_id, references(:users, on_delete: :nothing), null: true)
      add(:referral_type, :referral_type, null: false)
      add(:referral_code, :citext, null: false)
      add(:is_active, :boolean, null: false, default: true)
      timestamps()
    end

    create unique_index(:referral_sources, [:referral_type, :user_id],
             name: :referral_sources_type_user
           )

    create unique_index(:referral_sources, [:referral_code], name: :referral_sources_index_code)

    alter table(:users) do
      add(:referral_source_id, references(:referral_sources, on_delete: :nothing), null: true)
    end
  end
end
