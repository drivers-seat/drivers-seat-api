defmodule DriversSeatCoop.AppPreferencesTest do
  use DriversSeatCoop.DataCase
  alias DriversSeatCoop.AppPreferences

  @pref_1_key "key1"
  @pref_1_app_version "2.0.29"
  @pref_1_device_id "123456"
  @pref_1_value %{
    "prop1" => "key1_val1",
    "prop2" => "key1_val2"
  }

  @pref_2_key "key2"
  @pref_2_app_version "2.0.30"
  @pref_2_device_id "987654"
  @pref_2_value %{
    "prop1" => "key2_val1",
    "prop2" => "key2_val2"
  }

  @pref_2_updated_app_version "2.0.31"
  @pref_2_updated_device_id "201345673"
  @pref_2_updated_value %{
    "diff_prop1" => "keyTwo_val1",
    "diff_prop2" => "keyTwo_val2",
    "diff_prop3" => "keyTwo_val3"
  }

  describe "app_preferences" do
    test "set_user_app_preference sets values correctly" do
      user = Factory.create_user()

      {:ok, _} =
        AppPreferences.set_user_app_preference(user.id, %{
          device_id: @pref_1_device_id,
          app_version: @pref_1_app_version,
          key: @pref_1_key,
          value: @pref_1_value
        })

      {:ok, _} =
        AppPreferences.set_user_app_preference(user.id, %{
          device_id: @pref_2_device_id,
          app_version: @pref_2_app_version,
          key: @pref_2_key,
          value: @pref_2_value
        })

      actual =
        AppPreferences.get_user_app_preferences(user.id)
        |> Enum.sort_by(fn p -> p.key end)

      assert Enum.count(actual) == 2

      actual_1 = Enum.at(actual, 0)
      actual_2 = Enum.at(actual, 1)

      assert actual_1.user_id == user.id
      assert actual_1.key == @pref_1_key
      assert actual_1.value == @pref_1_value
      assert actual_1.last_updated_device_id == @pref_1_device_id
      assert actual_1.last_updated_app_version == @pref_1_app_version

      assert actual_2.user_id == user.id
      assert actual_2.key == @pref_2_key
      assert actual_2.value == @pref_2_value
      assert actual_2.last_updated_device_id == @pref_2_device_id
      assert actual_2.last_updated_app_version == @pref_2_app_version
    end

    test "set_user_app_preference only updates specific key" do
      user = Factory.create_user()

      {:ok, _} =
        AppPreferences.set_user_app_preference(user.id, %{
          device_id: @pref_1_device_id,
          app_version: @pref_1_app_version,
          key: @pref_1_key,
          value: @pref_1_value
        })

      {:ok, _} =
        AppPreferences.set_user_app_preference(user.id, %{
          device_id: @pref_2_device_id,
          app_version: @pref_2_app_version,
          key: @pref_2_key,
          value: @pref_2_value
        })

      {:ok, _} =
        AppPreferences.set_user_app_preference(user.id, %{
          device_id: @pref_2_updated_device_id,
          app_version: @pref_2_updated_app_version,
          key: @pref_2_key,
          value: @pref_2_updated_value
        })

      actual =
        AppPreferences.get_user_app_preferences(user.id)
        |> Enum.sort_by(fn p -> p.key end)

      assert Enum.count(actual) == 2

      actual_1 = Enum.at(actual, 0)
      actual_2 = Enum.at(actual, 1)

      assert actual_1.user_id == user.id
      assert actual_1.key == @pref_1_key
      assert actual_1.value == @pref_1_value
      assert actual_1.last_updated_device_id == @pref_1_device_id
      assert actual_1.last_updated_app_version == @pref_1_app_version

      assert actual_2.user_id == user.id
      assert actual_2.key == @pref_2_key
      assert actual_2.value == @pref_2_updated_value
      assert actual_2.last_updated_device_id == @pref_2_updated_device_id
      assert actual_2.last_updated_app_version == @pref_2_updated_app_version
    end
  end
end
