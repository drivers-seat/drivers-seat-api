defmodule DriversSeatCoop.AppPreferences do
  import Ecto.Query, warn: false
  alias DriversSeatCoop.AppPreferences.UserAppPreference
  alias DriversSeatCoop.Repo

  def get_default_preference_values(user_id) do
    [
      %UserAppPreference{
        key: :dashboard_layout,
        user_id: user_id,
        value: %{
          sections: [
            %{
              id: :transition,
              type: :campaign,
              header: nil,
              display_class: [
                :dashboard_toDos
              ],
              orientation: :horizontal,
              campaign_category: [
                :transition
              ],
              show_empty: false,
              empty_template: nil
            },
            # Top recommendations, visible only if there are new recommendations
            # This is handled by the UI
            %{
              id: :recommendations_top,
              type: :campaign,
              header: nil,
              display_class: [
                :dashboard_recommendations
              ],
              orientation: :horizontal,
              campaign_category: [
                :recommendations,
                :recommendations_accepted
              ],
              show_empty: true,
              # handled by custom code in the UI
              empty_template: nil
            },
            # Top todos, only visible if there are active To Dos.  Checklist is categorized based on if its complete
            %{
              id: :to_dos,
              type: :campaign,
              header: nil,
              display_class: [
                :dashboard_toDos
              ],
              orientation: :horizontal,
              campaign_category: [
                :to_dos
              ],
              show_empty: false,
              empty_template: nil
            },
            # Earnings Summary
            %{
              id: :earnings_summary,
              type: :custom,
              header: nil
            },
            # Informational Campaigns
            %{
              id: :info,
              type: :campaign,
              header: nil,
              display_class: [
                :dashboard_info
              ],
              orientation: :vertical,
              campaign_category: [
                :info
              ],
              show_empty: false,
              empty_template: nil
            },
            # Bottom recommendations only appear if there are accepted recommendations
            # and there are no new recommendations.  This is handled by the UI
            %{
              id: :recommendations_bottom,
              type: :campaign,
              header: nil,
              display_class: [
                :dashboard_recommendations
              ],
              orientation: :horizontal,
              campaign_category: [
                :recommendations,
                :recommendations_accepted
              ],
              show_empty: true,
              # handled by custom code in the UI
              empty_template: nil
            }
          ]
        }
      }
    ]
  end

  def set_user_app_preference(user_id, %{
        :device_id => last_updated_device_id,
        :app_version => last_updated_app_version,
        :key => key,
        :value => value
      }) do
    attrs = %{
      key: key,
      value: value,
      last_updated_device_id: last_updated_device_id,
      last_updated_app_version: last_updated_app_version
    }

    %UserAppPreference{user_id: user_id}
    |> UserAppPreference.changeset(attrs)
    |> Repo.insert(
      on_conflict:
        {:replace, [:value, :last_updated_device_id, :last_updated_app_version, :updated_at]},
      conflict_target: [:user_id, :key]
    )
  end

  def get_user_app_preferences(user_id) do
    query()
    |> query_filter_user_id(user_id)
    |> Repo.all()
  end

  def get_user_app_preference(user_id, key) do
    query()
    |> query_filter_user_id(user_id)
    |> query_filter_preference(key)
    |> Repo.one()
  end

  def query do
    from(p in UserAppPreference)
  end

  def query_filter_user_id(qry, user_id_or_ids, include \\ true) do
    user_id_or_ids = List.wrap(user_id_or_ids)

    if include,
      do: where(qry, [p], p.user_id in ^user_id_or_ids),
      else: where(qry, [p], p.user_id not in ^user_id_or_ids)
  end

  def query_filter_preference(qry, key_or_keys, include \\ true) do
    key_or_keys =
      List.wrap(key_or_keys)
      |> Enum.map(fn k -> "#{k}" end)

    if include,
      do: where(qry, [p], p.key in ^key_or_keys),
      else: where(qry, [p], p.key not in ^key_or_keys)
  end
end
