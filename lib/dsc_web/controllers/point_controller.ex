defmodule DriversSeatCoopWeb.PointController do
  use DriversSeatCoopWeb, :controller
  require Logger
  alias DriversSeatCoop.Driving

  plug DriversSeatCoopWeb.AuthenticationPlug
  action_fallback DriversSeatCoopWeb.FallbackController

  @doc """
  This route is the route all points should go through coming from the app.
  The structure of the JSON received is controlled by the plugin the app uses,
  and differs slightly from our database structure, so we transform it
  within the controller into our own map.

  The Cordova plugin source code is here:
  https://github.com/transistorsoft/cordova-background-geolocation-lt
  The plugin docs on the structure submitted are here (under "HTTP Post Schema"):
  https://transistorsoft.github.io/cordova-background-geolocation-lt/interfaces/location.html

  The app includes "user_id" and "trip_id" under the "extras" key, but the "user_id" field
  is not used on our side. Instead, the currently authenticated user_id is passed to the Point
  creation function and used to create points.

  The app will send a bulk array of points, currently capped at 60 on the app's side.

  Points created are not rendered back in the response as they aren't used by the app.
  """
  def create(conn, %{"location" => points_params}) do
    points_params = List.wrap(points_params)
    coords_attributes = ["latitude", "longitude", "accuracy", "speed", "heading", "altitude"]

    device = Map.get(conn.assigns, :dsc_device)

    device_id =
      if is_nil(device) do
        nil
      else
        device.id
      end

    points_params =
      Enum.map(points_params, fn params ->
        with {:ok, coords} <- Map.fetch(params, "coords"),
             new_params <- Map.take(coords, coords_attributes),
             {:ok, extras} <- Map.fetch(params, "extras"),
             new_params <- Map.merge(extras, new_params),
             {:ok, timestamp} <- Map.fetch(params, "timestamp") do
          activity_type = get_in(params, ["activity", "type"])
          activity_confidence = get_in(params, ["activity", "confidence"])
          battery_level = get_in(params, ["battery", "level"])
          battery_is_charging = get_in(params, ["battery", "is_charging"])
          is_moving = Map.get(params, "is_moving")

          Map.put(new_params, "recorded_at", timestamp)
          |> Map.put("activity_type", activity_type)
          |> Map.put("activity_confidence", activity_confidence)
          |> Map.put("battery_level", battery_level)
          |> Map.put("battery_is_charging", battery_is_charging)
          |> Map.put("is_moving", is_moving)
        else
          _ ->
            %{}
        end
      end)

    case Driving.create_points(points_params, conn.assigns.user.id, device_id) do
      {:ok, _points} ->
        nil

      {:error, changeset} ->
        Sentry.capture_message("failed to create many points",
          extra: %{changeset: inspect(changeset)}
        )
    end

    # ignore any failed points and return success (204)
    conn
    |> send_resp(:no_content, "")
  end
end
