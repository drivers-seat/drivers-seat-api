defmodule DriversSeatCoopWeb.AppPreferencesController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.AppPreferences
  alias DriversSeatCoopWeb.AppPreferencesValidator

  action_fallback DriversSeatCoopWeb.FallbackController

  def index(conn, _params) do
    user_preferences = AppPreferences.get_user_app_preferences(conn.assigns.user.id)
    default_preferences = AppPreferences.get_default_preference_values(conn.assigns.user.id)

    conn
    |> render("index.json", %{
      app_preferences: user_preferences,
      app_preference_defaults: default_preferences
    })
  end

  def update(conn, %{"id" => key, "value" => value}) do
    device = Map.get(conn.assigns, :dsc_device)

    params = %{
      key: key,
      value: value
    }

    params =
      if is_nil(device) do
        params
      else
        params
        |> Map.put(:device_id, Map.get(device, :device_id))
        |> Map.put(:app_version, Map.get(device, :app_version))
      end

    with {:ok, params} <- AppPreferencesValidator.update(params) do
      with {:ok, _} <- AppPreferences.set_user_app_preference(conn.assigns.user.id, params) do
        index(conn, params)
      end
    end
  end
end
