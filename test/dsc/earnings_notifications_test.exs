defmodule DriversSeatCoop.EarningsNotificationsTest do
  use DriversSeatCoop.DataCase

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Factory
  alias DriversSeatCoop.Marketing
  alias DriversSeatCoop.Notifications.Oban.ActivitiesUpdatedNotification

  describe "New Activities Notifications" do
    test "respects opt_out of push notifications" do
      user =
        Factory.create_user(%{
          opted_out_of_push_notifications: true
        })

      # Should not try to send for control group
      populations =
        Marketing.set_populations_for_user(user, :exp_activities_notif, :treatment_7d, false)

      assert Enum.count(populations) == 1

      assert {:do_not_send, :user_opted_out_of_push_notifications} ==
               ActivitiesUpdatedNotification.determine_activity_notification_action(user)
    end

    test "If user not notified before, select all activities" do
      user =
        Factory.create_user(%{
          inserted_at: ~N[2023-04-01 00:00:00],
          updated_at: ~N[2023-04-01 00:00:00]
        })

      # sets the last activity date
      Accounts.create_login_user_action(user, ~N[2023-04-04 00:00:00])

      # 3-day experiment group
      populations =
        Marketing.set_populations_for_user(user, :exp_activities_notif, :treatment_3d, false)

      assert Enum.count(populations) == 1

      # create activities
      activity_1 =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "earning_type" => "work",
          "status" => "completed",
          "pay" => 10.0,
          "inserted_at" => ~N[2023-05-01 00:00:00],
          "updated_at" => ~N[2023-05-01 00:00:00]
        })

      activity_2 =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "earning_type" => "work",
          "status" => "completed",
          "pay" => 10.0,
          "inserted_at" => ~N[2023-05-02 00:00:00],
          "updated_at" => ~N[2023-05-02 00:00:00]
        })

      # this activity was before this scheme, so it should not be included
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "earning_type" => "work",
        "status" => "completed",
        "pay" => 10.0,
        "inserted_at" => ~N[2023-04-03 00:00:00],
        "updated_at" => ~N[2023-04-03 00:00:00],
        "notification_required" => nil
      })

      {action, info} = ActivitiesUpdatedNotification.determine_activity_notification_action(user)

      assert action == :send
      assert get_activity_ids(info) == get_activity_ids([activity_1, activity_2])
    end

    test "ignores activities where notification required is false" do
      user =
        Factory.create_user(%{
          inserted_at: ~N[2023-04-01 00:00:00],
          updated_at: ~N[2023-04-01 00:00:00]
        })

      # sets the last activity date
      Accounts.create_login_user_action(user, ~N[2023-04-04 00:00:00])

      # 3-day experiment group
      populations =
        Marketing.set_populations_for_user(user, :exp_activities_notif, :treatment_3d, false)

      assert Enum.count(populations) == 1

      # this activity should not be sent b/c it has notification_required = false
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "earning_type" => "work",
        "status" => "completed",
        "pay" => 10.0,
        "inserted_at" => ~N[2023-05-01 00:00:00],
        "updated_at" => ~N[2023-05-01 00:00:00],
        "notification_required" => false
      })

      activity_2 =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "earning_type" => "work",
          "status" => "completed",
          "pay" => 10.0,
          "inserted_at" => ~N[2023-05-02 00:00:00],
          "updated_at" => ~N[2023-05-02 00:00:00]
        })

      {action, info} = ActivitiesUpdatedNotification.determine_activity_notification_action(user)

      assert action == :send
      assert get_activity_ids(info) == [activity_2.id]
    end

    test "ignores activities have been deleted" do
      user =
        Factory.create_user(%{
          inserted_at: ~N[2023-04-01 00:00:00],
          updated_at: ~N[2023-04-01 00:00:00]
        })

      # sets the last activity date
      Accounts.create_login_user_action(user, ~N[2023-04-04 00:00:00])

      # 3-day experiment group
      populations =
        Marketing.set_populations_for_user(user, :exp_activities_notif, :treatment_3d, false)

      assert Enum.count(populations) == 1

      # create activities
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "earning_type" => "work",
        "status" => "completed",
        "pay" => 10.0,
        "inserted_at" => ~N[2023-05-01 00:00:00],
        "updated_at" => ~N[2023-05-01 00:00:00],
        "deleted" => true
      })

      activity_2 =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "earning_type" => "work",
          "status" => "completed",
          "pay" => 10.0,
          "inserted_at" => ~N[2023-05-02 00:00:00],
          "updated_at" => ~N[2023-05-02 00:00:00]
        })

      {action, info} = ActivitiesUpdatedNotification.determine_activity_notification_action(user)

      assert action == :send
      assert get_activity_ids(info) == [activity_2.id]
    end

    test "selects activities since most recent notif date" do
      user =
        Factory.create_user(%{
          inserted_at: ~N[2023-04-01 00:00:00],
          updated_at: ~N[2023-04-01 00:00:00]
        })

      # sets the last activity date
      Accounts.create_login_user_action(user, ~N[2023-04-04 00:00:00])

      # 3-day experiment group
      populations =
        Marketing.set_populations_for_user(user, :exp_activities_notif, :treatment_3d, false)

      assert Enum.count(populations) == 1

      # create activities
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "earning_type" => "work",
        "status" => "completed",
        "pay" => 10.0,
        "inserted_at" => ~N[2023-04-15 00:00:00],
        "updated_at" => ~N[2023-04-18 00:00:00],
        "notification_required" => false,
        "notified_on" => ~N[2023-04-18 00:00:00]
      })

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "earning_type" => "work",
        "status" => "completed",
        "pay" => 10.0,
        "inserted_at" => ~N[2023-04-17 00:00:00],
        "updated_at" => ~N[2023-04-17 00:00:00]
      })

      # this activity is before the last action date and should not be included
      activity_3 =
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "earning_type" => "work",
          "status" => "completed",
          "pay" => 10.0,
          "inserted_at" => ~N[2023-04-20 00:00:00],
          "updated_at" => ~N[2023-04-20 00:00:00]
        })

      {action, info} = ActivitiesUpdatedNotification.determine_activity_notification_action(user)

      assert action == :send
      assert get_activity_ids(info) == [activity_3.id]
    end

    test "enforces 3-day wait period correctly using last action date" do
      user = Factory.create_user()

      # create a login from 4-days ago
      date = Date.utc_today() |> Date.add(-4)
      Accounts.create_login_user_action(user, NaiveDateTime.new!(date, ~T[00:00:00]))

      # establish a notified on date in the past
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "earning_type" => "work",
        "status" => "completed",
        "pay" => 10.0,
        "inserted_at" => ~N[2023-05-01 00:00:00],
        "updated_at" => ~N[2023-05-01 00:00:00],
        "notification_required" => false,
        "notified_on" => ~N[2023-04-01 00:00:00]
      })

      {action, _} = ActivitiesUpdatedNotification.determine_activity_notification_action(user)

      assert action == :send

      # create a login from 1-day ago which means that we are within the window
      # and should not send a notification
      date = Date.utc_today() |> Date.add(-1)
      Accounts.create_login_user_action(user, NaiveDateTime.new!(date, ~T[00:00:00]))

      assert {:do_not_send, :too_soon_since_last_usage} ==
               ActivitiesUpdatedNotification.determine_activity_notification_action(user)
    end

    test "enforces 3-day wait period correctly using last notif date" do
      user = Factory.create_user()

      # create a login from 4-days ago
      date = Date.utc_today() |> Date.add(-10)
      Accounts.create_login_user_action(user, NaiveDateTime.new!(date, ~T[00:00:00]))

      # establish a notified on date > than the window --> send
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "earning_type" => "work",
        "status" => "completed",
        "pay" => 10.0,
        "inserted_at" => ~N[2023-05-01 00:00:00],
        "updated_at" => ~N[2023-05-01 00:00:00],
        "notification_required" => false,
        "notified_on" => NaiveDateTime.new!(Date.utc_today() |> Date.add(-4), ~T[00:00:00])
      })

      {action, _} = ActivitiesUpdatedNotification.determine_activity_notification_action(user)

      assert action == :send

      # establish a notified on date < than the window --> do not send
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "earning_type" => "work",
        "status" => "completed",
        "pay" => 10.0,
        "inserted_at" => ~N[2023-05-01 00:00:00],
        "updated_at" => ~N[2023-05-01 00:00:00],
        "notification_required" => false,
        "notified_on" => NaiveDateTime.new!(Date.utc_today() |> Date.add(-2), ~T[00:00:00])
      })

      assert {:do_not_send, :too_soon_since_last_notification} ==
               ActivitiesUpdatedNotification.determine_activity_notification_action(user)
    end

    test "stops sending after 5 notifications with no actions" do
      user = Factory.create_user()

      # create a login from 10-days ago
      date = Date.utc_today() |> Date.add(-20)
      Accounts.create_login_user_action(user, NaiveDateTime.new!(date, ~T[00:00:00]))

      # create 4 different activities with different notification dates
      Enum.each(1..4, fn x ->
        Factory.create_activity(user.id, %{
          "timezone" => user.timezone,
          "employer" => "uber",
          "earning_type" => "work",
          "status" => "completed",
          "pay" => 10.0,
          "inserted_at" => ~N[2023-05-01 00:00:00],
          "updated_at" => ~N[2023-05-01 00:00:00],
          "notification_required" => false,
          "notified_on" => NaiveDateTime.new!(Date.add(date, x), ~T[00:00:00])
        })
      end)

      # since there are only 4 items, we should send
      {action, _} = ActivitiesUpdatedNotification.determine_activity_notification_action(user)
      assert action == :send

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "earning_type" => "work",
        "status" => "completed",
        "pay" => 10.0,
        "inserted_at" => ~N[2023-05-01 00:00:00],
        "updated_at" => ~N[2023-05-01 00:00:00],
        "notification_required" => false,
        "notified_on" => NaiveDateTime.new!(Date.add(date, 5), ~T[00:00:00])
      })

      # after the 5th item, we should not send
      assert {:do_not_send, :exceeded_notification_count_without_app_usage} ==
               ActivitiesUpdatedNotification.determine_activity_notification_action(user)

      Accounts.create_login_user_action(user, NaiveDateTime.new!(Date.add(date, 6), ~T[00:00:00]))

      {action, _} = ActivitiesUpdatedNotification.determine_activity_notification_action(user)
      assert action == :send
    end

    test "only considers login and session refresh actions for last usage" do
      user = Factory.create_user()

      # establish a prior notification date
      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => "uber",
        "earning_type" => "work",
        "status" => "completed",
        "pay" => 10.0,
        "inserted_at" => ~N[2023-05-01 00:00:00],
        "updated_at" => ~N[2023-05-01 00:00:00],
        "notification_required" => false,
        "notified_on" => ~N[2023-05-02 00:00:00]
      })

      # create a login from 20-days ago
      date = Date.utc_today() |> Date.add(-20)
      Accounts.create_login_user_action(user, NaiveDateTime.new!(date, ~T[00:00:00]))

      {action, _} = ActivitiesUpdatedNotification.determine_activity_notification_action(user)
      assert action == :send

      Accounts.create_reset_password_user_action(user, NaiveDateTime.utc_now())

      {action, _} = ActivitiesUpdatedNotification.determine_activity_notification_action(user)
      assert action == :send

      Accounts.create_session_refresh_user_action(user, NaiveDateTime.utc_now())

      assert {:do_not_send, :too_soon_since_last_usage} ==
               ActivitiesUpdatedNotification.determine_activity_notification_action(user)
    end
  end

  defp get_activity_ids(activities) do
    activities
    |> Enum.map(fn a -> a.id end)
    |> Enum.sort()
  end
end
