defmodule DriversSeatCoop.HubSpotTest do
  use DriversSeatCoop.DataCase

  alias DriversSeatCoop.HubSpot

  describe "hubspot" do
    test "enabled?/0 returns false during tests" do
      assert not HubSpot.enabled?()
    end

    test "is_bad_email?/1 works with nil email addresses" do
      assert HubSpot.is_bad_email?(nil)
    end

    test "is_bad_email?/1 works with invalid email addresses" do
      assert HubSpot.is_bad_email?("thisisnot@emailaddress")
    end

    test "is_bad_email?/1 works with bad email addresses" do
      assert HubSpot.is_bad_email?("lyzzi@rokkincat.com")
    end

    test "is_bad_email?/1 works with good email addresses" do
      assert not HubSpot.is_bad_email?("good-email@example.com")
    end

    test "user_properties/1 works" do
      user = Factory.create_user()
      properties = HubSpot.user_properties(user)

      user_id = user.id
      user_email = user.email

      assert [
               %{property: "email", value: ^user_email},
               %{property: "became_registered_user_date", value: became_registered_user_date},
               %{property: "app_user_id", value: ^user_id},
               %{property: "app_services_long_form_", value: "food"},
               %{property: "type", value: "Driver"},
               %{property: "channel_source", value: "App Registration"}
             ] = properties

      assert became_registered_user_date > 1_640_000_000_000
    end
  end
end
