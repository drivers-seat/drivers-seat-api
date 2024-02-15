defmodule DriversSeatCoop.Repo.Migrations.DeprecateAnalyticsUserMetroArea do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add_if_not_exists(:metro_area_id, references(:region_metro_area, on_delete: :nothing))
    end

    # execute("""
    #   WITH tmp AS 
    #   (
    #     SELECT      U.id AS user_id
    #             ,   COALESCE(pcu.region_id_metro_area, pca.region_id_metro_area) AS metro_area_id
    #     FROM        users U
    #     LEFT JOIN   region_postal_code    pcu ON pcu.postal_code = u.postal_code
    #     LEFT JOIN   region_postal_code    pca ON pca.postal_code = u.postal_code_argyle
    #   )
    #   UPDATE  users U
    #   SET     metro_area_id = (SELECT t.metro_area_id FROM tmp t WHERE t.user_id = U.id)
    # """)
  end
end
