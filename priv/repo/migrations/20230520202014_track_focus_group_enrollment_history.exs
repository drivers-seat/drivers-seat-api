defmodule DriversSeatCoop.Repo.Migrations.TrackFocusGroupEnrollmentHistory do
  use Ecto.Migration

  def change do
    create table(:focus_group_memberships) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:focus_group_id, references(:research_groups, on_delete: :nothing), null: false)
      add(:enroll_date, :utc_datetime, null: false)
      add(:unenroll_date, :utc_datetime, null: true)
      timestamps()
    end

    create unique_index(:focus_group_memberships, [:user_id, :focus_group_id, :enroll_date],
             name: :focus_group_memberships_ak
           )

    execute("""
      INSERT INTO public.focus_group_memberships(user_id, focus_group_id, enroll_date, unenroll_date, inserted_at, updated_at)
      SELECT U.id, R.id, COALESCE(U.enrolled_research_at, U.unenrolled_research_at, U.updated_at), U.unenrolled_research_at, COALESCE(U.enrolled_research_at, U.unenrolled_research_at, U.updated_at), COALESCE(U.unenrolled_research_at, U.updated_at)
      FROM users U
      JOIN research_groups R ON LOWER(U.focus_group) = LOWER(R.code)
    """)
  end
end
