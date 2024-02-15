defmodule DriversSeatCoopWeb.ArgyleWebhookControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true
  use Oban.Testing, repo: DriversSeatCoop.Repo

  alias DriversSeatCoop.Argyle.Oban.{GetNewActivities, ImportArgyleProfileInformation}
  alias DriversSeatCoop.Driving
  alias DriversSeatCoop.Earnings.Oban.UpdateTimeSpansForUserWorkday
  alias DriversSeatCoop.Util.DateTimeUtil

  @argyle_account_id "017c9454-ae45-92b4-d036-258c5d00e4c2"

  setup %{conn: conn} do
    user =
      Factory.create_user_with_argyle_fields(%{
        timezone: "America/Los_Angeles"
      })

    conn = put_req_header(conn, "accept", "*/*")

    {:ok, conn: conn, user: user}
  end

  describe "activities.removed event" do
    test "triggers a job when a valid user is given (activities.removed)", %{
      conn: conn,
      user: user
    } do
      activity1 = Factory.create_activity(%{"user_id" => user.id})
      activity2 = Factory.create_activity(%{"user_id" => user.id})

      payload = %{
        name: "test webhook",
        event: "activities.removed",
        data: %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          available_from: "2019-04-15T16:31:06Z",
          available_to: "2022-07-24T14:52:41Z",
          available_count: 2998,
          removed_from: "2022-07-04T14:42:33Z",
          removed_to: "2022-07-05T17:41:00Z",
          removed_count: 2,
          removed_activities: [
            activity1.activity_id,
            activity2.activity_id
          ]
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert %{deleted: true} = Driving.get_activity(activity1.id)
      assert %{deleted: true} = Driving.get_activity(activity2.id)

      # check to make sure calculate earnings was scheduled for each dat affected
      {:ok, start_dt, _} = DateTime.from_iso8601("2022-07-04T14:42:33Z")
      {:ok, end_dt, _} = DateTime.from_iso8601("2022-07-05T17:41:00Z")

      start_dt = DateTimeUtil.datetime_to_working_day(start_dt, "America/Los_Angeles")
      end_dt = DateTimeUtil.datetime_to_working_day(end_dt, "America/Los_Angeles")

      Date.range(start_dt, end_dt)
      |> Enum.each(fn work_date ->
        assert_enqueued(
          worker: UpdateTimeSpansForUserWorkday,
          args: %{
            user_id: user.id,
            work_date: "#{work_date}"
          }
        )
      end)
    end

    test "triggers a job when a valid user is given (gigs.removed)", %{conn: conn, user: user} do
      activity1 = Factory.create_activity(%{"user_id" => user.id})
      activity2 = Factory.create_activity(%{"user_id" => user.id})

      payload = %{
        name: "test webhook",
        event: "gigs.removed",
        data: %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          available_from: "2019-04-15T16:31:06Z",
          available_to: "2022-07-24T14:52:41Z",
          available_count: 2998,
          removed_from: "2022-07-04T14:42:33Z",
          removed_to: "2022-07-05T17:41:00Z",
          removed_count: 2,
          removed_gigs: [
            activity1.activity_id,
            activity2.activity_id
          ]
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert %{deleted: true} = Driving.get_activity(activity1.id)
      assert %{deleted: true} = Driving.get_activity(activity2.id)

      # check to make sure calculate earnings was scheduled for each dat affected
      {:ok, start_dt, _} = DateTime.from_iso8601("2022-07-04T14:42:33Z")
      {:ok, end_dt, _} = DateTime.from_iso8601("2022-07-05T17:41:00Z")

      start_dt = DateTimeUtil.datetime_to_working_day(start_dt, "America/Los_Angeles")
      end_dt = DateTimeUtil.datetime_to_working_day(end_dt, "America/Los_Angeles")

      Date.range(start_dt, end_dt)
      |> Enum.each(fn work_date ->
        assert_enqueued(
          worker: UpdateTimeSpansForUserWorkday,
          args: %{
            user_id: user.id,
            work_date: "#{work_date}"
          }
        )
      end)
    end

    test "returns error when invalid user is given (activities.removed)", %{
      conn: conn,
      user: user
    } do
      activity1 = Factory.create_activity(%{"user_id" => user.id})
      activity2 = Factory.create_activity(%{"user_id" => user.id})

      payload = %{
        name: "test webhook",
        event: "activities.removed",
        data: %{
          "account" => @argyle_account_id,
          "user" => "some id that doesn't exist",
          available_from: "2019-04-15T16:31:06Z",
          available_to: "2022-07-24T14:52:41Z",
          available_count: 2998,
          removed_from: "2022-07-04T14:42:33Z",
          removed_to: "2022-07-05T17:41:00Z",
          removed_count: 2,
          removed_activities: [
            activity1.activity_id,
            activity2.activity_id
          ]
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "user not found" == response(conn, 422)

      assert %{deleted: false} = Driving.get_activity(activity1.id)
      assert %{deleted: false} = Driving.get_activity(activity2.id)
    end

    test "returns error when invalid user is given (gigs.removed)", %{conn: conn, user: user} do
      activity1 = Factory.create_activity(%{"user_id" => user.id})
      activity2 = Factory.create_activity(%{"user_id" => user.id})

      payload = %{
        name: "test webhook",
        event: "gigs.removed",
        data: %{
          "account" => @argyle_account_id,
          "user" => "some id that doesn't exist",
          available_from: "2019-04-15T16:31:06Z",
          available_to: "2022-07-24T14:52:41Z",
          available_count: 2998,
          removed_from: "2022-07-04T14:42:33Z",
          removed_to: "2022-07-05T17:41:00Z",
          removed_count: 2,
          removed_activities: [
            activity1.activity_id,
            activity2.activity_id
          ]
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "user not found" == response(conn, 422)

      assert %{deleted: false} = Driving.get_activity(activity1.id)
      assert %{deleted: false} = Driving.get_activity(activity2.id)
    end
  end

  describe "activities.added event" do
    test "triggers a job when a valid user is given (activities.added)", %{conn: conn, user: user} do
      payload = %{
        "name" => "test webhook",
        "event" => "activities.added",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "available_from" => "2018-02-08T14:55:41Z",
          "available_to" => "2022-03-18T22:19:22Z",
          "available_count" => 5866,
          "added_from" => "2022-03-06T02:57:52Z",
          "added_to" => "2022-03-18T22:19:22Z",
          "added_count" => 2
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: GetNewActivities,
        args: %{
          argyle_account_id: @argyle_account_id,
          user_id: user.id,
          from_start_date: "2022-03-06T02:57:52Z",
          to_start_date: "2022-03-18T22:19:22Z"
        }
      )
    end

    test "triggers a job when a valid user is given (gigs.added)", %{conn: conn, user: user} do
      payload = %{
        "name" => "test webhook",
        "event" => "gigs.added",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "available_from" => "2018-02-08T14:55:41Z",
          "available_to" => "2022-03-18T22:19:22Z",
          "available_count" => 5866,
          "added_from" => "2022-03-06T02:57:52Z",
          "added_to" => "2022-03-18T22:19:22Z",
          "added_count" => 2
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: GetNewActivities,
        args: %{
          argyle_account_id: @argyle_account_id,
          user_id: user.id,
          from_start_date: "2022-03-06T02:57:52Z",
          to_start_date: "2022-03-18T22:19:22Z"
        }
      )
    end

    test "returns error when invalid user is given (activities.added)", %{conn: conn, user: _user} do
      payload = %{
        "name" => "test webhook",
        "event" => "activities.added",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => "some id that doesn't exist",
          "available_from" => "2018-02-08T14:55:41Z",
          "available_to" => "2022-03-18T22:19:22Z",
          "available_count" => 5866,
          "added_from" => "2022-03-06T02:57:52Z",
          "added_to" => "2022-03-18T22:19:22Z",
          "added_count" => 2
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "user not found" == response(conn, 422)

      refute_enqueued(worker: GetNewActivities)
    end

    test "returns error when invalid user is given (gigs.added)", %{conn: conn, user: _user} do
      payload = %{
        "name" => "test webhook",
        "event" => "gigs.added",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => "some id that doesn't exist",
          "available_from" => "2018-02-08T14:55:41Z",
          "available_to" => "2022-03-18T22:19:22Z",
          "available_count" => 5866,
          "added_from" => "2022-03-06T02:57:52Z",
          "added_to" => "2022-03-18T22:19:22Z",
          "added_count" => 2
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "user not found" == response(conn, 422)

      refute_enqueued(worker: GetNewActivities)
    end
  end

  describe "activities.updated event" do
    test "triggers a job when a valid user is given (activities.updated)", %{
      conn: conn,
      user: user
    } do
      payload = %{
        "name" => "test webhook",
        "event" => "activities.updated",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "available_from" => "2021-02-22T22:46:32Z",
          "available_to" => "2022-03-21T04:21:54Z",
          "available_count" => 881,
          "updated_from" => "2022-03-06T02:57:52Z",
          "updated_to" => "2022-03-18T22:19:22Z",
          "updated_count" => 2,
          "updated_activities" => [
            "017f9619-f44e-5932-d0af-b608224aa603",
            "017fa777-1ba5-dbfc-ff6d-478b156e4dee"
          ]
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: GetNewActivities,
        args: %{
          argyle_account_id: @argyle_account_id,
          user_id: user.id,
          from_start_date: "2022-03-06T02:57:52Z",
          to_start_date: "2022-03-18T22:19:22Z"
        }
      )
    end

    test "triggers a job when a valid user is givenm (gigs.updated)", %{conn: conn, user: user} do
      payload = %{
        "name" => "test webhook",
        "event" => "gigs.updated",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "available_from" => "2021-02-22T22:46:32Z",
          "available_to" => "2022-03-21T04:21:54Z",
          "available_count" => 881,
          "updated_from" => "2022-03-06T02:57:52Z",
          "updated_to" => "2022-03-18T22:19:22Z",
          "updated_count" => 2,
          "updated_activities" => [
            "017f9619-f44e-5932-d0af-b608224aa603",
            "017fa777-1ba5-dbfc-ff6d-478b156e4dee"
          ]
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: GetNewActivities,
        args: %{
          argyle_account_id: @argyle_account_id,
          user_id: user.id,
          from_start_date: "2022-03-06T02:57:52Z",
          to_start_date: "2022-03-18T22:19:22Z"
        }
      )
    end
  end

  describe "activities.fully_synced event" do
    test "triggers a job when a valid user is given (activities.fully_synced)", %{
      conn: conn,
      user: user
    } do
      payload = %{
        "name" => "test webhook",
        "event" => "activities.fully_synced",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "available_from" => "2022-03-06T02:57:52Z",
          "available_to" => "2022-03-18T22:19:22Z",
          "available_count" => 1
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: GetNewActivities,
        args: %{
          argyle_account_id: @argyle_account_id,
          user_id: user.id,
          from_start_date: "2022-03-06T02:57:52Z",
          to_start_date: "2022-03-18T22:19:22Z"
        }
      )
    end

    test "triggers a job when a valid user is given (gigs.fully_synced)", %{
      conn: conn,
      user: user
    } do
      payload = %{
        "name" => "test webhook",
        "event" => "gigs.fully_synced",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "available_from" => "2022-03-06T02:57:52Z",
          "available_to" => "2022-03-18T22:19:22Z",
          "available_count" => 1
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: GetNewActivities,
        args: %{
          argyle_account_id: @argyle_account_id,
          user_id: user.id,
          from_start_date: "2022-03-06T02:57:52Z",
          to_start_date: "2022-03-18T22:19:22Z"
        }
      )
    end

    test "ignores event when nil dates are given", %{conn: conn, user: user} do
      payload = %{
        "name" => "test webhook",
        "event" => "activities.fully_synced",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "available_from" => nil,
          "available_to" => nil,
          "available_count" => 0
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      refute_enqueued(worker: GetNewActivities)
    end
  end

  describe "profiles.added event" do
    test "triggers a job when a valid user is given (profiles.added)", %{conn: conn, user: user} do
      payload = %{
        "name" => "test webhook",
        "event" => "profiles.added",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "profile" => "017cf0b4-65e5-81b6-2069-55da1d4d3445"
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: ImportArgyleProfileInformation,
        args: %{user_id: user.id}
      )
    end

    test "triggers a job when a valid user is given (identities.added)", %{conn: conn, user: user} do
      payload = %{
        "name" => "test webhook",
        "event" => "identities.added",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "profile" => "017cf0b4-65e5-81b6-2069-55da1d4d3445"
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: ImportArgyleProfileInformation,
        args: %{user_id: user.id}
      )
    end

    test "returns error when invalid user is given", %{conn: conn, user: _user} do
      payload = %{
        "name" => "test webhook",
        "event" => "profiles.added",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => "some id that doesn't exist",
          "profile" => "017cf0b4-65e5-81b6-2069-55da1d4d3445"
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "user not found" == response(conn, 422)

      refute_enqueued(worker: ImportArgyleProfileInformation)
    end
  end

  describe "profiles.updated event" do
    test "triggers a job when a valid user is given (profiles.updated)", %{conn: conn, user: user} do
      payload = %{
        "name" => "test webhook",
        "event" => "profiles.updated",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "profile" => "017cf0b4-65e5-81b6-2069-55da1d4d3445"
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: ImportArgyleProfileInformation,
        args: %{user_id: user.id}
      )
    end

    test "triggers a job when a valid user is given (identities.updated)", %{
      conn: conn,
      user: user
    } do
      payload = %{
        "name" => "test webhook",
        "event" => "identities.updated",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "profile" => "017cf0b4-65e5-81b6-2069-55da1d4d3445"
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: ImportArgyleProfileInformation,
        args: %{user_id: user.id}
      )
    end
  end

  describe "vehicles.added event" do
    test "triggers a job when a valid user is given", %{conn: conn, user: user} do
      payload = %{
        "name" => "test webhook",
        "event" => "vehicles.added",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "vehicle" => "017fd107-1fb4-b973-7d25-becdc5348316"
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: ImportArgyleProfileInformation,
        args: %{user_id: user.id}
      )
    end
  end

  describe "vehicles.updated event" do
    test "triggers a job when a valid user is given", %{conn: conn, user: user} do
      payload = %{
        "name" => "test webhook",
        "event" => "vehicles.updated",
        "data" => %{
          "account" => @argyle_account_id,
          "user" => user.argyle_user_id,
          "vehicle" => "017fd107-1fb4-b973-7d25-becdc5348316"
        }
      }

      conn = post(conn, Routes.argyle_webhook_path(conn, :create), payload)

      assert "" == response(conn, 204)

      assert_enqueued(
        worker: ImportArgyleProfileInformation,
        args: %{user_id: user.id}
      )
    end
  end
end
