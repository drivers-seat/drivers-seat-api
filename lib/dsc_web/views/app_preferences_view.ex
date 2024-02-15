defmodule DriversSeatCoopWeb.AppPreferencesView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.AppPreferencesView

  def render("index.json", %{
        app_preferences: user_preferences,
        app_preference_defaults: default_preferences
      }) do
    app_preferences =
      (List.wrap(user_preferences) ++ List.wrap(default_preferences))
      |> Enum.reduce(%{}, fn pref, result ->
        Map.put_new(result, "#{pref.key}", pref)
      end)
      |> Map.values()

    %{data: render_many(app_preferences, AppPreferencesView, "app_preference.json")}
  end

  def render("app_preference.json", %{app_preferences: app_preference}) do
    %{
      key: app_preference.key,
      value: app_preference.value,
      last_updated_device_id: app_preference.last_updated_device_id,
      last_updated_app_version: app_preference.last_updated_app_version
    }
  end
end
