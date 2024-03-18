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
            # Any alerts to show here
            %{
              id: :alerts,
              type: :campaign,
              header: nil,
              display_class: [
                :dashboard_notifications
              ],
              orientation: :vertical,
              campaign_category: [
                :alerts
              ],
              show_empty: false,
              empty_template: nil
            },

            # To-dos, only visible if there are active To Dos.  
            # Checklist is categorized based on if its complete
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
              orientation: :horizontal,
              campaign_category: [
                :info
              ],
              show_empty: false,
              empty_template: nil
            }
          ]
        }
      },
      %UserAppPreference{
        key: :example_custom_page,
        user_id: user_id,
        value: %{
          title: ["Custom Page Example"],
          description: ["Look at this custom page of campaign cards"],
          sections: [
            # Any alerts to show here
            %{
              id: :top,
              type: :campaign,
              display_class: [
                :dashboard_info
              ],
              orientation: :vertical,
              campaign_category: [
                :custom_top
              ],
              show_empty: false,
              empty_template: nil
            },
            %{
              id: :horiz_1,
              type: :campaign,
              slides_per_row: 3,
              header: %{
                title: ["3 Horizontal Card Header"],
                description: [
                  "Look at me, I'm 3-horiztonal cards in a row",
                ]
              },
              footer: %{
                title: ["3 Horizontal Card Footer"],
                description: [
                  "Thanks",
                ]
              },
              display_class: [
                :dashboard_info
              ],
              orientation: :horizontal,
              campaign_category: [
                :custom_horizontal_1
              ],
              show_empty: false,
              empty_template: nil
            },
            %{
              id: :horiz_2,
              type: :campaign,
              display_class: [
                :dashboard_info
              ],
              orientation: :horizontal,
              campaign_category: [
                :custom_horizontal_2
              ],
              show_empty: false,
              empty_template: nil
            },
            %{
              id: :vert_2,
              type: :campaign,
              display_class: [
                :dashboard_info
              ],
              orientation: :vertical,
              campaign_category: [
                :custom_vertical_2
              ],
              show_empty: false,
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
