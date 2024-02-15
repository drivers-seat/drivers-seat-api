defmodule DriversSeatCoop.ActivitiesTest do
  use DriversSeatCoop.DataCase
  alias DriversSeatCoop.Activities
  alias DriversSeatCoop.Driving
  alias DriversSeatCoop.Employers
  alias DriversSeatCoop.Util.DateTimeUtil

  @activity_data %{
    "id" => "017cba30-c9f8-14b1-3e34-4df700d2a01e",
    "type" => "rideshare",
    "route" =>
      "https://partners.uber.com/p3/payments/trips/7d61af37-b072-49d9-ae01-3ff2905c44e9?in_app=true",
    "income" => %{
      "pay" => "9.04",
      "fees" => "2.85",
      "tips" => "0.58",
      "bonus" => "1.39",
      "taxes" => nil,
      "total" => "9.04",
      "currency" => "USD",
      "total_charge" => "11.89"
    },
    "status" => "completed",
    "account" => "017cb9ce-ff24-e324-a994-ab7517b151b6",
    "distance" => "4.71",
    "duration" => 609,
    "employer" => "uber",
    "end_date" => "2018-09-26T03:41:16Z",
    "metadata" => %{},
    "timezone" => "America/Los_Angeles",
    "link_item" => "uber",
    "num_tasks" => 1,
    "created_at" => "2021-10-26T01:22:12.088Z",
    "start_date" => "2018-09-26T03:32:07Z",
    "updated_at" => "2021-10-26T01:22:12.088Z",
    "data_partner" => "goober",
    "earning_type" => "work",
    "end_location" => %{
      "lat" => "32.6316850336",
      "lng" => "-117.1350988917",
      "formatted_address" => "Coronado Bay Rd, Coronado, CA 92118, USA"
    },
    "income_rates" => %{
      "hour" => 2.83,
      "mile" => 4.93
    },
    "all_datetimes" => %{
      "break_end" => nil,
      "pickup_at" => "2018-09-26T03:33:07Z",
      "shift_start" => "2018-09-26T01:32:07Z",
      "shift_end" => "2018-09-26T04:32:07Z",
      "dropoff_at" => "2018-09-26T03:41:16Z",
      "request_at" => "2018-09-26T03:18:21Z",
      "cancel_at" => "2018-09-26T02:18:21Z",
      "accept_at" => "2018-09-26T02:21:21Z",
      "break_start" => nil
    },
    "circumstances" => %{
      "is_pool" => false,
      "is_rush" => true,
      "is_surge" => false,
      "position" => nil,
      "service_type" => "UberXL"
    },
    "distance_unit" => "miles",
    "all_timestamps" => %{
      "break_end" => nil,
      "pickup_at" => 1_537_932_727,
      "shift_end" => nil,
      "dropoff_at" => 1_537_933_336,
      "request_at" => 1_537_931_901,
      "break_start" => nil,
      "shift_start" => nil
    },
    "start_location" => %{
      "lat" => "32.6823228744",
      "lng" => "-117.177730168",
      "formatted_address" => "Adella Ave, Coronado, CA 92118, USA"
    },
    "complete_data_available" => true
  }

  describe "activity field mapping" do
    test "overall function" do
      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(@activity_data, user.id, false)

      assert activity.activity_id == "017cba30-c9f8-14b1-3e34-4df700d2a01e"
      assert activity.deleted == false
      assert activity.service_class == "rideshare"
      assert activity.employer == "uber"
      assert activity.employer_service == "UberXL"
      assert activity.data_partner == "goober"
      assert activity.earning_type == "work"
      assert activity.currency == "USD"
      assert activity.income_rate_hour_cents == 283
      assert activity.income_rate_mile_cents == 493
      assert activity.status == "completed"
      assert activity.distance == Decimal.new("4.71")
      assert activity.distance_unit == "miles"
      assert activity.duration_seconds == 609
      assert activity.timezone == "America/Los_Angeles"
      assert activity.timestamp_start == ~U[2018-09-26 03:32:07Z]
      assert activity.timestamp_end == ~U[2018-09-26 03:41:16Z]
      assert activity.timestamp_request == ~U[2018-09-26 03:18:21Z]
      assert activity.timestamp_accept == ~U[2018-09-26 02:21:21Z]
      assert activity.timestamp_cancel == ~U[2018-09-26 02:18:21Z]
      assert activity.timestamp_pickup == ~U[2018-09-26 03:33:07Z]
      assert activity.timestamp_dropoff == ~U[2018-09-26 03:41:16Z]
      assert activity.timestamp_shift_start == ~U[2018-09-26 01:32:07Z]
      assert activity.timestamp_shift_end == ~U[2018-09-26 04:32:07Z]
      assert activity.is_pool == false
      assert activity.is_rush == true
      assert activity.is_surge == false
      assert activity.start_location_address == "Adella Ave, Coronado, CA 92118, USA"

      assert activity.start_location_geometry == %Geo.Point{
               coordinates: {-117.177730168, 32.6823228744},
               srid: 4326,
               properties: %{}
             }

      assert activity.end_location_address == "Coronado Bay Rd, Coronado, CA 92118, USA"

      assert activity.end_location_geometry == %Geo.Point{
               coordinates: {-117.1350988917, 32.6316850336},
               srid: 4326,
               properties: %{}
             }

      assert activity.earnings_pay_cents == 904
      assert activity.earnings_tip_cents == 58
      assert activity.earnings_bonus_cents == 139
      assert activity.earnings_total_cents == 904
      assert activity.charges_fees_cents == 285
      assert activity.charges_taxes_cents == nil
      assert activity.charges_total_cents == 1189
      assert activity.working_day_start == ~D[2018-09-25]
      assert activity.working_day_end == ~D[2018-09-25]
      assert activity.timestamp_work_start == ~U[2018-09-26 03:33:07Z]
      assert activity.timestamp_work_end == ~U[2018-09-26 03:41:16Z]
      assert activity.tasks_total == 1
    end

    test "uses start date when pickup is empty" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["all_datetimes", "pickup_at"], nil)

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)
      assert activity.timestamp_pickup == nil
      assert activity.timestamp_start == ~U[2018-09-26 03:32:07Z]
      assert activity.timestamp_work_start == ~U[2018-09-26 03:32:07Z]
    end

    test "uses cancel date when dropoff is empty" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["all_datetimes", "dropoff_at"], nil)

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)
      assert activity.timestamp_dropoff == nil
      assert activity.timestamp_cancel == ~U[2018-09-26 02:18:21Z]
      assert activity.timestamp_end == ~U[2018-09-26 03:41:16Z]
      assert activity.timestamp_work_end == ~U[2018-09-26 02:18:21Z]
    end

    test "uses end date when dropoff and cancel are empty" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["all_datetimes", "dropoff_at"], nil)
      activity_data = put_in(activity_data, ["all_datetimes", "cancel_at"], nil)

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)
      assert activity.timestamp_dropoff == nil
      assert activity.timestamp_cancel == nil
      assert activity.timestamp_end == ~U[2018-09-26 03:41:16Z]
      assert activity.timestamp_work_end == ~U[2018-09-26 03:41:16Z]
    end

    test "uses end date and druation when start date is empty" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["all_datetimes", "pickup_at"], nil)
      activity_data = put_in(activity_data, ["start_date"], nil)

      expected_work_start = DateTime.add(~U[2018-09-26 03:41:16Z], -609, :second)

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)
      assert activity.timestamp_pickup == nil
      assert activity.timestamp_start == nil
      assert activity.timestamp_end == ~U[2018-09-26 03:41:16Z]
      assert activity.timestamp_work_end == ~U[2018-09-26 03:41:16Z]
      assert activity.timestamp_work_start == expected_work_start
      assert not is_nil(activity.working_day_start)
      assert not is_nil(activity.working_day_end)
    end

    test "uses start date and druation when end date is empty" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["all_datetimes", "dropoff_at"], nil)
      activity_data = put_in(activity_data, ["all_datetimes", "cancel_at"], nil)
      activity_data = put_in(activity_data, ["end_date"], nil)

      expected_work_end = DateTime.add(~U[2018-09-26 03:33:07Z], 609, :second)

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)
      assert activity.timestamp_dropoff == nil
      assert activity.timestamp_end == nil
      assert activity.timestamp_cancel == nil

      assert activity.timestamp_start == ~U[2018-09-26 03:32:07Z]
      assert activity.timestamp_pickup == ~U[2018-09-26 03:33:07Z]
      assert activity.timestamp_work_end == expected_work_end
      assert activity.timestamp_work_start == ~U[2018-09-26 03:33:07Z]
      assert not is_nil(activity.working_day_start)
      assert not is_nil(activity.working_day_end)
    end

    test "handles all dates empty" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["all_datetimes", "request_at"], nil)
      activity_data = put_in(activity_data, ["all_datetimes", "pickup_at"], nil)
      activity_data = put_in(activity_data, ["all_datetimes", "dropoff_at"], nil)
      activity_data = put_in(activity_data, ["all_datetimes", "cancel_at"], nil)
      activity_data = put_in(activity_data, ["all_datetimes", "accept_at"], nil)
      activity_data = put_in(activity_data, ["start_date"], nil)
      activity_data = put_in(activity_data, ["end_date"], nil)

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)
      assert activity.timestamp_dropoff == nil
      assert activity.timestamp_end == nil
      assert activity.timestamp_start == nil
      assert activity.timestamp_pickup == nil
      assert activity.timestamp_work_end == nil
      assert activity.timestamp_work_start == nil
      assert activity.working_day_end == nil
      assert activity.working_day_start == nil
    end

    test "work date is based on timezone of the activity" do
      user =
        Factory.create_user(%{
          timezone: "America/New_York"
        })

      activity_data = put_in(@activity_data, ["timezone"], "America/Los_Angeles")

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.timestamp_work_start == ~U[2018-09-26 03:33:07Z]
      assert activity.timestamp_work_end == ~U[2018-09-26 03:41:16Z]

      assert activity.working_day_start ==
               DateTimeUtil.datetime_to_working_day(
                 activity.timestamp_work_start,
                 activity.timezone
               )

      assert activity.working_day_end ==
               DateTimeUtil.datetime_to_working_day(
                 activity.timestamp_work_end,
                 activity.timezone
               )
    end

    test "work date is based on user's time zone when none is supplied in activity data" do
      user =
        Factory.create_user(%{
          timezone: "America/New_York"
        })

      activity_data =
        @activity_data
        |> put_in(["timezone"], nil)

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert is_nil(activity.timezone)

      assert activity.working_day_start ==
               DateTimeUtil.datetime_to_working_day(activity.timestamp_work_start, user.timezone)

      assert activity.working_day_end ==
               DateTimeUtil.datetime_to_working_day(activity.timestamp_work_end, user.timezone)
    end

    test "work date implements 4am day start" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      {:ok, pickup_time_local, _} = DateTime.from_iso8601("2023-03-09 03:58:00.000000-08:00")
      {:ok, dropoff_time_local, _} = DateTime.from_iso8601("2023-03-09 04:03:00.000000-08:00")

      activity_data =
        @activity_data
        |> put_in(["all_datetimes", "pickup_at"], DateTime.to_iso8601(pickup_time_local))
        |> put_in(["all_datetimes", "dropoff_at"], DateTime.to_iso8601(dropoff_time_local))

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.working_day_start == ~D[2023-03-08]
      assert activity.working_day_end == ~D[2023-03-09]
    end

    test "For New Activities, notification_required set to true where earnings > 0" do
      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(@activity_data, user.id, false)

      assert activity.notification_required == true
    end

    test "For New Activities, notification_required not set to true where earnings <= 0" do
      user = Factory.create_user()

      activity_data =
        @activity_data
        |> put_in(["income", "pay"], "0.0")
        |> put_in(["income", "tips"], nil)
        |> put_in(["income", "bonus"], "0.0")
        |> put_in(["income", "total"], nil)

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.notification_required == false
    end

    test "For Updated Activities, notification_required set to true on items where earnings have changed" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["income", "pay"], "37.98")

      {:ok, activity_1} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity_1.notification_required == true

      {1, _} = Activities.update_notification_sent(activity_1.id)
      activity_2 = Activities.get_activity(user.id, activity_1.id)

      assert activity_2.notification_required == false
      assert not is_nil(activity_2.notified_on)
      assert activity_1.id == activity_2.id

      activity_data = put_in(@activity_data, ["income", "pay"], "42.95")

      {:ok, activity_3} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity_3.notification_required == true
      assert activity_1.id == activity_2.id
      assert activity_1.id == activity_3.id
    end

    test "For Updated Activities, notification_required not set to true on items where earnings have not changed" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["income", "pay"], "37.98")

      {:ok, activity_1} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity_1.notification_required == true

      {1, _} = Activities.update_notification_sent(activity_1.id)
      activity_2 = Activities.get_activity(user.id, activity_1.id)

      assert activity_2.notification_required == false
      assert not is_nil(activity_2.notified_on)
      assert activity_1.id == activity_2.id

      {:ok, activity_3} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity_3.notification_required == false
      assert activity_1.id == activity_2.id
      assert activity_1.id == activity_3.id
    end

    test "For Updated Activities, notification_required remains true if it was true and earnings have not changed" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["income", "pay"], "37.98")

      {:ok, activity_1} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity_1.notification_required == true

      {:ok, activity_2} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity_2.notification_required == true
      assert activity_1.id == activity_2.id
    end

    test "For Updated Activities that are deletes, notification_required is always set to false" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["income", "pay"], "37.98")

      {:ok, activity_1} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity_1.notification_required == true

      {:ok, activity_2} = Driving.upsert_activity(activity_data, user.id, true)

      assert activity_2.notification_required == false
      assert activity_1.id == activity_2.id
    end

    test "For Updated Activities that are deletes, notification_required is always set to false even when income is updated" do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["income", "pay"], "37.98")

      {:ok, activity_1} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity_1.notification_required == true

      {1, _} = Activities.update_notification_sent(activity_1.id)
      activity_2 = Activities.get_activity(user.id, activity_1.id)

      activity_data = put_in(@activity_data, ["income", "pay"], "45.82")

      {:ok, activity_3} = Driving.upsert_activity(activity_data, user.id, true)

      assert activity_3.notification_required == false
      assert activity_1.id == activity_2.id
      assert activity_1.id == activity_3.id
    end

    test "Delete activities sets notification_required to false " do
      user = Factory.create_user()

      activity_data = put_in(@activity_data, ["income", "pay"], "37.98")

      {:ok, activity_1} = Driving.upsert_activity(activity_data, user.id, true)

      assert activity_1.notification_required == true
    end

    test "Update overwrites missing mapped values with NULL if not present in update" do
      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(@activity_data, user.id, false)

      assert activity.activity_id == "017cba30-c9f8-14b1-3e34-4df700d2a01e"
      assert activity.deleted == false
      assert activity.service_class == "rideshare"
      assert activity.employer == "uber"
      assert activity.employer_service == "UberXL"
      assert activity.data_partner == "goober"
      assert activity.earning_type == "work"
      assert activity.currency == "USD"
      assert activity.income_rate_hour_cents == 283
      assert activity.income_rate_mile_cents == 493
      assert activity.status == "completed"
      assert activity.distance == Decimal.new("4.71")
      assert activity.distance_unit == "miles"
      assert activity.duration_seconds == 609
      assert activity.timezone == "America/Los_Angeles"
      assert activity.timestamp_start == ~U[2018-09-26 03:32:07Z]
      assert activity.timestamp_end == ~U[2018-09-26 03:41:16Z]
      assert activity.timestamp_request == ~U[2018-09-26 03:18:21Z]
      assert activity.timestamp_accept == ~U[2018-09-26 02:21:21Z]
      assert activity.timestamp_cancel == ~U[2018-09-26 02:18:21Z]
      assert activity.timestamp_pickup == ~U[2018-09-26 03:33:07Z]
      assert activity.timestamp_dropoff == ~U[2018-09-26 03:41:16Z]
      assert activity.timestamp_shift_start == ~U[2018-09-26 01:32:07Z]
      assert activity.timestamp_shift_end == ~U[2018-09-26 04:32:07Z]
      assert activity.is_pool == false
      assert activity.is_rush == true
      assert activity.is_surge == false
      assert activity.start_location_address == "Adella Ave, Coronado, CA 92118, USA"

      updated_activity_data =
        Map.take(@activity_data, [
          "id"
        ])

      {:ok, updated_activity} = Driving.upsert_activity(updated_activity_data, user.id, false)

      assert updated_activity.id == activity.id
      assert updated_activity.activity_id == "017cba30-c9f8-14b1-3e34-4df700d2a01e"
      assert updated_activity.deleted == false
      assert updated_activity.service_class == nil
      assert updated_activity.employer == nil
      assert updated_activity.employer_service == nil
      assert updated_activity.data_partner == nil
      assert updated_activity.earning_type == nil
      assert updated_activity.currency == nil
      assert updated_activity.income_rate_hour_cents == nil
      assert updated_activity.income_rate_mile_cents == nil
      assert updated_activity.status == nil
      assert updated_activity.distance == nil
      assert updated_activity.distance_unit == nil
      assert updated_activity.duration_seconds == nil
      assert updated_activity.timezone == nil
      assert updated_activity.timestamp_start == nil
      assert updated_activity.timestamp_end == nil
      assert updated_activity.timestamp_request == nil
      assert updated_activity.timestamp_accept == nil
      assert updated_activity.timestamp_cancel == nil
      assert updated_activity.timestamp_pickup == nil
      assert updated_activity.timestamp_dropoff == nil
      assert updated_activity.timestamp_shift_start == nil
      assert updated_activity.timestamp_shift_end == nil
      assert updated_activity.is_pool == nil
      assert updated_activity.is_rush == nil
      assert updated_activity.is_surge == nil
      assert updated_activity.start_location_address == nil
    end
  end

  describe "employer matches" do
    test "matches on employer_name before data_partner" do
      test_employer_name = "employer_#{Ecto.UUID.generate()}"
      test_data_partner = "data_partner_#{Ecto.UUID.generate()}"

      activity_data =
        @activity_data
        |> Map.put("employer", test_employer_name)
        |> Map.put("data_partner", test_data_partner)

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      employer = Employers.get_employer_by_name(test_employer_name)

      assert activity != nil
      assert employer != nil
      assert activity.employer == test_employer_name
      assert activity.data_partner == test_data_partner
      assert activity.employer_id == employer.id
    end

    test "matches on data_partner if employer_name not found" do
      test_employer_name = "employer_#{Ecto.UUID.generate()}"
      test_data_partner = "data_partner_#{Ecto.UUID.generate()}"

      # make sure that the employer exists for data partner.
      # since we're using UUIDs, the employer will not exist
      employer = Employers.get_or_create_employer(test_data_partner)

      activity_data =
        @activity_data
        |> Map.put("employer", test_employer_name)
        |> Map.put("data_partner", test_data_partner)

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity != nil
      assert employer != nil
      assert activity.employer == test_employer_name
      assert activity.data_partner == test_data_partner
      assert activity.employer_id == employer.id
    end

    test "handles null employer info - employer and data partner" do
      activity_data =
        @activity_data
        |> Map.put("employer", nil)
        |> Map.put("data_partner", nil)

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity != nil
      assert activity.employer == nil
      assert activity.data_partner == nil
      assert activity.employer_id == nil
    end

    test "handles null employer info - employer not data partner" do
      test_data_partner = "data_partner_#{Ecto.UUID.generate()}"

      activity_data =
        @activity_data
        |> Map.put("employer", nil)
        |> Map.put("data_partner", test_data_partner)

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      employer = Employers.get_employer_by_name(test_data_partner)

      assert activity != nil
      assert activity.employer == nil
      assert activity.data_partner == test_data_partner
      assert activity.employer_id == employer.id
    end

    test "matches are case insensitive" do
      test_employer_name = "employer_#{Ecto.UUID.generate()}"
      test_data_partner = "data_partner_#{Ecto.UUID.generate()}"

      activity_data =
        @activity_data
        |> Map.put("employer", String.upcase(test_employer_name))
        |> Map.put("data_partner", String.upcase(test_data_partner))

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      employer = Employers.get_employer_by_name(test_employer_name)

      assert activity != nil
      assert employer != nil
      assert activity.employer == String.upcase(test_employer_name)
      assert activity.data_partner == String.upcase(test_data_partner)
      assert activity.employer_id == employer.id
    end
  end

  describe "service class matches" do
    test "match service class on name" do
      test_service_class_name = "sc_#{Ecto.UUID.generate()}"

      activity_data =
        @activity_data
        |> Map.put("type", test_service_class_name)

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      service_class = Employers.get_or_create_service_class(test_service_class_name)

      assert service_class != nil
      assert activity != nil
      assert activity.service_class_id == service_class.id
    end

    test "handles nil value" do
      activity_data =
        @activity_data
        |> Map.put("type", nil)

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity != nil
      assert activity.service_class_id == nil
    end

    test "handles empty value" do
      activity_data =
        @activity_data
        |> Map.put("type", " ")

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity != nil
      assert activity.service_class_id == nil
    end
  end

  describe "employer service class matches" do
    test "Creates new employer service class when combo not found" do
      test_employer = Employers.get_or_create_employer("employer_#{Ecto.UUID.generate()}")
      test_service_class = Employers.get_or_create_service_class("sc__#{Ecto.UUID.generate()}")

      activity_data =
        @activity_data
        |> Map.put("employer", test_employer.name)
        |> Map.put("data_partner", nil)
        |> Map.put("type", test_service_class.name)

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.employer_id == test_employer.id
      assert activity.service_class_id == test_service_class.id

      employer_service_class =
        Employers.get_or_create_employer_service_class(
          activity.service_class_id,
          activity.employer_id
        )

      assert activity.employer_service_class_id == employer_service_class.id
    end

    test "Matches to preexisting employer service class" do
      test_employer = Employers.get_or_create_employer("employer_#{Ecto.UUID.generate()}")
      test_service_class = Employers.get_or_create_service_class("sc__#{Ecto.UUID.generate()}")

      test_employer_service_class =
        Employers.get_or_create_employer_service_class(test_service_class.id, test_employer.id)

      activity_data =
        @activity_data
        |> Map.put("employer", test_employer.name)
        |> Map.put("data_partner", nil)
        |> Map.put("type", test_service_class.name)

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.employer_id == test_employer.id
      assert activity.service_class_id == test_service_class.id
      assert activity.employer_service_class_id == test_employer_service_class.id
    end

    test "No Employer Service Class without Employer" do
      # test_employer = Employers.get_or_create_employer("employer_#{Ecto.UUID.generate()}")
      test_service_class = Employers.get_or_create_service_class("sc__#{Ecto.UUID.generate()}")

      # test_employer_service_class = Employers.get_or_create_employer_service_class(test_service_class.id, test_employer.id)

      activity_data =
        @activity_data
        |> Map.put("employer", nil)
        |> Map.put("data_partner", nil)
        |> Map.put("type", test_service_class.name)

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.employer_id == nil
      assert activity.service_class_id == test_service_class.id
      assert activity.employer_service_class_id == nil
    end

    test "No Employer Service Class without Service Class" do
      test_employer = Employers.get_or_create_employer("employer_#{Ecto.UUID.generate()}")
      # test_service_class = Employers.get_or_create_service_class("sc__#{Ecto.UUID.generate()}")
      # test_employer_service_class = Employers.get_or_create_employer_service_class(test_service_class.id, test_employer.id)

      activity_data =
        @activity_data
        |> Map.put("employer", test_employer.name)
        |> Map.put("data_partner", test_employer.name)
        |> Map.put("type", nil)

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.employer_id == test_employer.id
      assert activity.service_class_id == nil
      assert activity.employer_service_class_id == nil
    end
  end

  describe "insights start time" do
    test "Favors Accept Date over Request, Pickup, or Start" do
      activity_data =
        @activity_data
        |> Map.put("start_date", "2018-09-26T04:00:00Z")
        |> Map.put(
          "all_datetimes",
          %{
            "request_at" => "2018-09-26T01:00:00Z",
            "accept_at" => "2018-09-26T02:00:00Z",
            "cancel_at" => "2018-09-26T02:30:21Z",
            "pickup_at" => "2018-09-26T03:00:00Z",
            "dropoff_at" => "2018-09-26T05:00:00Z"
          }
        )
        |> Map.put("end_date", "2018-09-26T06:00:00Z")

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.timestamp_insights_work_start == activity.timestamp_accept
    end

    test "Favors Request over Pickup or Start when Accept is empty" do
      activity_data =
        @activity_data
        |> Map.put("start_date", "2018-09-26T04:00:00Z")
        |> Map.put(
          "all_datetimes",
          %{
            "request_at" => "2018-09-26T01:00:00Z",
            "cancel_at" => "2018-09-26T02:30:21Z",
            "pickup_at" => "2018-09-26T03:00:00Z",
            "dropoff_at" => "2018-09-26T05:00:00Z"
          }
        )
        |> Map.put("end_date", "2018-09-26T06:00:00Z")

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.timestamp_insights_work_start == activity.timestamp_request
    end

    test "Favors Pickup over Start when Accept and Request are empty" do
      activity_data =
        @activity_data
        |> Map.put("start_date", "2018-09-26T04:00:00Z")
        |> Map.put(
          "all_datetimes",
          %{
            "cancel_at" => "2018-09-26T02:30:21Z",
            "pickup_at" => "2018-09-26T03:00:00Z",
            "dropoff_at" => "2018-09-26T05:00:00Z"
          }
        )
        |> Map.put("end_date", "2018-09-26T06:00:00Z")

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.timestamp_insights_work_start == activity.timestamp_pickup
    end

    test "Uses Start when Accept, Request, and Pickup are empty" do
      activity_data =
        @activity_data
        |> Map.put("start_date", "2018-09-26T04:00:00Z")
        |> Map.put(
          "all_datetimes",
          %{
            "cancel_at" => "2018-09-26T02:30:21Z",
            "dropoff_at" => "2018-09-26T05:00:00Z"
          }
        )
        |> Map.put("end_date", "2018-09-26T06:00:00Z")

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.timestamp_insights_work_start == activity.timestamp_start
    end

    test "Floors the start time to no more than 2x job duration" do
      activity_data =
        @activity_data
        |> Map.put("start_date", "2018-09-26T04:00:00Z")
        |> Map.put(
          "all_datetimes",
          %{
            "request_at" => "2018-09-26T01:00:00Z"
          }
        )
        |> Map.put("end_date", "2018-09-26T05:00:00Z")

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.timestamp_work_start == ~U[2018-09-26 04:00:00Z]
      assert activity.timestamp_work_end == ~U[2018-09-26 05:00:00Z]

      # since the duration of the job was 1 hour, the insights start cannot occur more than 2 hours,
      # or 2x the work duration, before the job start
      assert activity.timestamp_insights_work_start == ~U[2018-09-26 02:00:00Z]
    end
  end

  describe "Activity Hours" do
    test "Calculates hours appropriately and proprotionally" do
      activity_data =
        @activity_data
        |> Map.put("timezone", "America/Los_Angeles")
        |> Map.put("start_date", "2018-09-26T03:28:00Z")
        |> Map.put("distance", "40.00")
        |> Map.put("distance_unit", "miles")
        |> Map.put(
          "all_datetimes",
          %{
            "cancel_at" => "2018-09-26T02:30:21Z",
            "dropoff_at" => "2018-09-26T05:19:00Z"
          }
        )
        |> Map.put("income", %{
          "pay" => "9.00",
          "fees" => "2.00",
          "tips" => "2.00",
          "bonus" => "9.00",
          "taxes" => nil,
          "total" => "20.00",
          "currency" => "USD",
          "total_charge" => "11.89"
        })
        |> Map.put("end_date", "2018-09-26T06:00:00Z")

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.timestamp_insights_work_start == ~U[2018-09-26 03:28:00Z]
      assert activity.timestamp_work_end == ~U[2018-09-26 05:19:00Z]
      assert activity.timezone == "America/Los_Angeles"
      assert activity.earnings_total_cents == 2_000
      assert activity.distance == Decimal.round(Decimal.from_float(40.0), 2)

      # this represents 9/25/2018 20:28 - 22:19, $20.00

      activity_hours =
        Activities.get_activity_hours_for_activity(activity.id)
        |> Enum.sort_by(fn ah -> {ah.date_local, ah.hour_local} end)

      hour_1 = Enum.at(activity_hours, 0)
      hour_2 = Enum.at(activity_hours, 1)
      hour_3 = Enum.at(activity_hours, 2)

      assert Enum.count(activity_hours) == 3
      assert Enum.all?(activity_hours, fn ah -> ah.date_local == ~D[2018-09-25] end)
      assert Enum.all?(activity_hours, fn ah -> ah.week_start_date == ~D[2018-09-23] end)
      assert Enum.all?(activity_hours, fn ah -> ah.day_of_week == 2 end)

      assert hour_1.hour_local == ~T[20:00:00]
      assert hour_1.duration_seconds == 1_920
      assert hour_1.percent_of_activity == 0.288
      assert hour_1.earnings_total_cents == 577
      assert hour_1.distance_miles == Decimal.from_float(11.53)

      assert hour_2.hour_local == ~T[21:00:00]
      assert hour_2.duration_seconds == 3_600
      assert hour_2.percent_of_activity == 0.541
      assert hour_2.earnings_total_cents == 1081
      assert hour_2.distance_miles == Decimal.from_float(21.62)

      assert hour_3.hour_local == ~T[22:00:00]
      assert hour_3.duration_seconds == 1_140
      assert hour_3.percent_of_activity == 0.171
      assert hour_3.earnings_total_cents == 342
      assert hour_3.distance_miles == Decimal.from_float(6.85)
    end

    test "Handles Updates" do
      activity_data =
        @activity_data
        |> Map.put("timezone", "America/Los_Angeles")
        |> Map.put("start_date", "2018-09-26T03:28:00Z")
        |> Map.put("distance", "40.00")
        |> Map.put("distance_unit", "miles")
        |> Map.put(
          "all_datetimes",
          %{
            "cancel_at" => "2018-09-26T02:30:21Z",
            "dropoff_at" => "2018-09-26T05:19:00Z"
          }
        )
        |> Map.put("income", %{
          "pay" => "9.00",
          "fees" => "2.00",
          "tips" => "2.00",
          "bonus" => "9.00",
          "taxes" => nil,
          "total" => "20.00",
          "currency" => "USD",
          "total_charge" => "11.89"
        })
        |> Map.put("end_date", "2018-09-26T06:00:00Z")

      user = Factory.create_user()

      {:ok, activity_0} = Driving.upsert_activity(activity_data, user.id, false)

      activity_data =
        @activity_data
        |> Map.put("timezone", "America/Los_Angeles")
        |> Map.put("start_date", "2018-09-26T04:28:00Z")
        |> Map.put("distance", "40.00")
        |> Map.put("distance_unit", "miles")
        |> Map.put(
          "all_datetimes",
          %{
            "cancel_at" => "2018-09-26T02:30:21Z",
            "dropoff_at" => "2018-09-26T05:19:00Z"
          }
        )
        |> Map.put("income", %{
          "pay" => "9.00",
          "fees" => "2.00",
          "tips" => "2.00",
          "bonus" => "9.00",
          "taxes" => nil,
          "total" => "20.00",
          "currency" => "USD",
          "total_charge" => "11.89"
        })
        |> Map.put("end_date", "2018-09-26T06:00:00Z")

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      # we are talking about the same activity
      assert activity_0.id == activity.id

      assert activity.timestamp_insights_work_start == ~U[2018-09-26 04:28:00Z]
      assert activity.timestamp_work_end == ~U[2018-09-26 05:19:00Z]
      assert activity.timezone == "America/Los_Angeles"
      assert activity.earnings_total_cents == 2_000
      assert activity.distance == Decimal.round(Decimal.from_float(40.0), 2)

      # this represents 9/25/2018 21:28 - 22:19, $20.00

      activity_hours =
        Activities.get_activity_hours_for_activity(activity.id)
        |> Enum.sort_by(fn ah -> {ah.date_local, ah.hour_local} end)

      hour_1 = Enum.at(activity_hours, 0)
      hour_2 = Enum.at(activity_hours, 1)
      hour_3 = Enum.at(activity_hours, 2)

      assert Enum.count(activity_hours) == 2

      assert Enum.all?(activity_hours, fn ah -> ah.date_local == ~D[2018-09-25] end)
      assert Enum.all?(activity_hours, fn ah -> ah.week_start_date == ~D[2018-09-23] end)
      assert Enum.all?(activity_hours, fn ah -> ah.day_of_week == 2 end)

      assert hour_1.hour_local == ~T[21:00:00]
      assert hour_1.duration_seconds == 1_920
      assert hour_1.percent_of_activity == 0.627
      assert hour_1.earnings_total_cents == 1255
      assert hour_1.distance_miles == Decimal.round(Decimal.from_float(25.10), 2)

      assert hour_2.hour_local == ~T[22:00:00]
      assert hour_2.duration_seconds == 1_140
      assert hour_2.percent_of_activity == 0.373
      assert hour_2.earnings_total_cents == 745
      assert hour_2.distance_miles == Decimal.round(Decimal.from_float(14.90), 2)

      assert hour_3 == nil
    end

    test "Handles Deletes" do
      activity_data =
        @activity_data
        |> Map.put("timezone", "America/Los_Angeles")
        |> Map.put("start_date", "2018-09-26T03:28:00Z")
        |> Map.put("distance", "40.00")
        |> Map.put("distance_unit", "miles")
        |> Map.put(
          "all_datetimes",
          %{
            "cancel_at" => "2018-09-26T02:30:21Z",
            "dropoff_at" => "2018-09-26T05:19:00Z"
          }
        )
        |> Map.put("income", %{
          "pay" => "9.00",
          "fees" => "2.00",
          "tips" => "2.00",
          "bonus" => "9.00",
          "taxes" => nil,
          "total" => "20.00",
          "currency" => "USD",
          "total_charge" => "11.89"
        })
        |> Map.put("end_date", "2018-09-26T06:00:00Z")

      user = Factory.create_user()

      {:ok, activity_0} = Driving.upsert_activity(activity_data, user.id, false)
      activity_hours = Activities.get_activity_hours_for_activity(activity_0.id)

      assert Enum.count(activity_hours) == 3

      activity_data =
        activity_data
        |> Map.put("timezone", "America/Los_Angeles")
        |> Map.put("distance", "40.00")
        |> Map.put("distance_unit", "miles")
        |> Map.put("start_date", "2018-09-26T04:28:00Z")
        |> Map.put("duration", nil)
        |> Map.put("end_date", nil)
        |> Map.put(
          "all_datetimes",
          %{}
        )
        |> Map.put("income", %{
          "pay" => "9.00",
          "fees" => "2.00",
          "tips" => "2.00",
          "bonus" => "9.00",
          "taxes" => nil,
          "total" => "20.00",
          "currency" => "USD",
          "total_charge" => "11.89"
        })

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      # we are talking about the same activity
      assert activity_0.id == activity.id

      activity_hours = Activities.get_activity_hours_for_activity(activity.id)

      assert activity_hours == []
    end

    test "Crosses day and week boundaries" do
      activity_data =
        @activity_data
        |> Map.put("timezone", "America/Los_Angeles")
        |> Map.put("start_date", "2018-09-23T06:28:00Z")
        |> Map.put("distance", "40.00")
        |> Map.put("distance_unit", "miles")
        |> Map.put(
          "all_datetimes",
          %{
            "cancel_at" => "2018-09-23T02:30:21Z",
            "dropoff_at" => "2018-09-23T08:19:00Z"
          }
        )
        |> Map.put("income", %{
          "pay" => "9.00",
          "fees" => "2.00",
          "tips" => "2.00",
          "bonus" => "9.00",
          "taxes" => nil,
          "total" => "20.00",
          "currency" => "USD",
          "total_charge" => "11.89"
        })
        |> Map.put("end_date", "2018-09-23T06:00:00Z")

      user = Factory.create_user()

      {:ok, activity} = Driving.upsert_activity(activity_data, user.id, false)

      assert activity.timestamp_insights_work_start == ~U[2018-09-23 06:28:00Z]
      assert activity.timestamp_work_end == ~U[2018-09-23 08:19:00Z]
      assert activity.timezone == "America/Los_Angeles"
      assert activity.earnings_total_cents == 2_000
      assert activity.distance == Decimal.round(Decimal.from_float(40.0), 2)

      # this represents 9/25/2018 20:28 - 22:19, $20.00

      activity_hours =
        Activities.get_activity_hours_for_activity(activity.id)
        |> Enum.sort_by(fn ah -> {ah.date_local, ah.hour_local} end)

      hour_1 = Enum.at(activity_hours, 0)
      hour_2 = Enum.at(activity_hours, 1)
      hour_3 = Enum.at(activity_hours, 2)

      assert Enum.count(activity_hours) == 3

      assert hour_1.hour_local == ~T[23:00:00]
      assert hour_1.date_local == ~D[2018-09-22]
      assert hour_1.week_start_date == ~D[2018-09-16]
      assert hour_1.day_of_week == 6
      assert hour_1.duration_seconds == 1_920
      assert hour_1.percent_of_activity == 0.288
      assert hour_1.earnings_total_cents == 577
      assert hour_1.distance_miles == Decimal.from_float(11.53)

      assert hour_2.hour_local == ~T[00:00:00]
      assert hour_2.date_local == ~D[2018-09-23]
      assert hour_2.week_start_date == ~D[2018-09-23]
      assert hour_2.day_of_week == 0
      assert hour_2.duration_seconds == 3_600
      assert hour_2.percent_of_activity == 0.541
      assert hour_2.earnings_total_cents == 1081
      assert hour_2.distance_miles == Decimal.from_float(21.62)

      assert hour_3.hour_local == ~T[01:00:00]
      assert hour_2.date_local == ~D[2018-09-23]
      assert hour_2.week_start_date == ~D[2018-09-23]
      assert hour_2.day_of_week == 0
      assert hour_3.duration_seconds == 1_140
      assert hour_3.percent_of_activity == 0.171
      assert hour_3.earnings_total_cents == 342
      assert hour_3.distance_miles == Decimal.from_float(6.85)
    end
  end
end
