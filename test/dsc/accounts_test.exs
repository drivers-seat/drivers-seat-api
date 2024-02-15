defmodule DriversSeatCoop.AccountsTest do
  use DriversSeatCoop.DataCase
  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Activities
  alias DriversSeatCoop.Earnings
  alias DriversSeatCoop.Goals
  alias DriversSeatCoop.ReferralSources
  alias DriversSeatCoop.Shifts

  describe "users" do
    alias DriversSeatCoop.Accounts.User

    @valid_attrs %{
      email: "some@example.com",
      password: "password",
      timezone: "America/Chicago",
      timezone_device: "America/Chicago",
      first_name: "some first name",
      last_name: "some last name",
      vehicle_make: "some vehicle make",
      vehicle_model: "some vehicle model",
      vehicle_type: "car",
      vehicle_year: 2019,
      service_names: ["food delivery"]
    }
    @update_attrs %{
      email: "some_updated@example.com",
      password: "updated password",
      timezone: "Jamaica",
      timezone_device: "Jamaica",
      first_name: "some updated name",
      last_name: "some updated last name",
      vehicle_make: "some updated vehicle make",
      vehicle_model: "some updated vehicle model",
      vehicle_type: "bike",
      vehicle_year: 2020,
      service_names: ["updated food delivery"]
    }
    @invalid_attrs %{
      email: nil,
      password: nil,
      timezone: nil,
      timezone_device: nil,
      vehicle_make: nil,
      vehicle_model: nil,
      vehicle_type: nil,
      vehicle_year: nil,
      service_names: nil
    }

    test "list_users/0 returns all users" do
      user = Factory.create_user()
      assert Accounts.list_users() == [user]
    end

    test "list_users_with_argyle_linked/0 returns no users when none are linked" do
      _user = Factory.create_user()
      assert Accounts.list_users_with_argyle_linked() == []
    end

    test "list_users_with_argyle_linked/0 returns relevant users" do
      user = Factory.create_user_with_argyle_fields()
      assert Accounts.list_users_with_argyle_linked() == [user]
    end

    test "list_user_ids/0 returns all users" do
      user = Factory.create_user()
      assert Accounts.list_user_ids() == [user.id]
    end

    test "get_user!/1 returns the user with given id" do
      user = Factory.create_user()
      assert Accounts.get_user!(user.id) == user
    end

    test "get_user_by_email/1 does case insensitive search for matching email" do
      expected_user = Factory.create_user(email: "TEST@EXAMPLE.COM")
      actual_user = Accounts.get_user_by_email("Test@Example.com")

      assert expected_user.id == actual_user.id
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some@example.com"
      assert is_binary(user.password_hash)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "create_user/1 with duplicate email returns error changeset" do
      %User{} = Factory.create_user(email: "TEST@EXAMPLE.COM")

      assert {:error, %Ecto.Changeset{errors: [email: {"has already been taken", _}]}} =
               Accounts.create_user(Map.put(@valid_attrs, :email, "test@example.com"))
    end

    test "create_user/1 creates accepted_terms upon creation" do
      terms = Factory.create_terms()
      Application.put_env(:dsc, :terms_v1_id, terms.id)
      user = Factory.create_user()

      accepted_terms =
        DriversSeatCoop.Legal.get_accepted_terms_by_terms_id_and_user_id(terms.id, user.id)

      assert accepted_terms.terms_id == terms.id
      assert accepted_terms.user_id == user.id
      assert accepted_terms.accepted_at == user.inserted_at
    after
      Application.delete_env(:dsc, :terms_v1_id)
    end

    test "create_user/1 sets referral_source_id based on referral_code" do
      {:ok, referral_source} =
        ReferralSources.create_referral_source(%{
          referral_type: "app_invite_menu",
          referral_code: "ABCD"
        })

      user =
        Factory.create_user(%{
          referral_code: "ABCD"
        })

      assert user.referral_source_id == referral_source.id
    end

    test "create_user/1 fails with inactive referral_code" do
      ReferralSources.create_referral_source(%{
        referral_type: "app_invite_menu",
        referral_code: "ABCD",
        is_active: false
      })

      assert {:error, cs = %Ecto.Changeset{}} =
               Accounts.create_user(Map.put(@valid_attrs, :referral_code, "ABCD"))

      assert %{referral_code: ["referral code is no longer active"]} == errors_on(cs)
    end

    test "create_user/1 fails with invalid referral_code" do
      assert {:error, cs = %Ecto.Changeset{}} =
               Accounts.create_user(Map.put(@valid_attrs, :referral_code, "XYZA"))

      assert %{referral_code: ["referral code not found"]} == errors_on(cs)
    end

    test "update_user/2 with valid data updates the user" do
      user = Factory.create_user()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "some_updated@example.com"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = Factory.create_user()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "update_user/2 with invalid vehicle_type returns error changeset" do
      user = Factory.create_user()

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_user(user, %{vehicle_type: "fake_vehicle"})

      assert user == Accounts.get_user!(user.id)
    end

    test "update_user/2 with invalid timezone returns error changeset" do
      user = Factory.create_user()

      assert {:error, cs = %Ecto.Changeset{}} =
               Accounts.update_user(user, %{timezone: "fake/timezone"})

      assert %{timezone: ["invalid timezone"]} == errors_on(cs)

      assert user == Accounts.get_user!(user.id)
    end

    test "update_user/2 fails with invalid referral_code" do
      user = Factory.create_user()

      assert {:error, cs = %Ecto.Changeset{}} =
               Accounts.update_user(user, %{referral_code: "ABCD"})

      assert %{referral_code: ["referral code not found"]} == errors_on(cs)

      assert user == Accounts.get_user!(user.id)
    end

    test "update_user/2 fails with inactive referral_code" do
      user = Factory.create_user()

      ReferralSources.create_referral_source(%{
        referral_type: "app_invite_menu",
        referral_code: "ABCD",
        is_active: false
      })

      assert {:error, cs = %Ecto.Changeset{}} =
               Accounts.update_user(user, %{referral_code: "ABCD"})

      assert %{referral_code: ["referral code is no longer active"]} == errors_on(cs)

      assert user == Accounts.get_user!(user.id)
    end

    test "update_user/2 only updates referral_source when it is in the attributes" do
      {:ok, ref_source} =
        ReferralSources.create_referral_source(%{
          referral_type: "app_invite_menu",
          referral_code: "ABCD"
        })

      user =
        Factory.create_user(%{
          referral_code: "ABCD"
        })

      {:ok, actual_user} = Accounts.update_user(user, %{last_name: "test"})

      assert ref_source.id == user.referral_source_id
      assert ref_source.id == actual_user.referral_source_id
      assert "test" == actual_user.last_name
    end

    test "delete_user/1 marks the user as deleted" do
      user = Factory.create_user()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert %{deleted: true} = Accounts.get_user!(user.id)
    end

    test "purge_user!/1 fails if user has not been marked for deletion" do
      user = Factory.create_user()
      assert {:error, :user_has_not_been_marked_for_deletion} = Accounts.purge_user!(user.id)
    end

    test "purge_user!/1 removes user completely" do
      user = Factory.create_user()

      Factory.create_device(user.id, "device")
      Factory.create_point(%{user_id: user.id})
      Factory.create_shift(%{user_id: user.id})
      Factory.create_expense(%{user_id: user.id})
      Factory.create_device(user.id, "1234")
      Factory.create_activity(%{"user_id" => user.id})
      Factory.create_earnings_goal(user.id, 10_000, :day)

      [shift_start_date, shift_end_date] = Shifts.get_shift_date_range(user)
      [job_start_date, job_end_date] = Activities.get_activity_date_range(user.id)

      dates =
        [
          shift_start_date,
          shift_end_date,
          job_start_date,
          job_end_date
        ]
        |> Enum.filter(fn x -> not is_nil(x) end)

      min_date = Enum.min(dates, Date)
      max_date = Enum.max(dates, Date)

      Date.range(min_date, max_date)
      |> Enum.each(fn work_date ->
        Earnings.update_timespans_and_allocations_for_user_workday(user, work_date)
      end)

      Date.range(min_date, max_date)
      |> Enum.each(fn work_date ->
        Goals.calculate_goal_performance(user.id, :earnings, :day, work_date)
      end)

      Accounts.delete_user(user)

      assert {:ok, %User{}} = Accounts.purge_user!(user.id)
      assert nil == Accounts.get_user(user.id)
    end

    test "change_user/1 returns a user changeset" do
      user = Factory.create_user()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "reset_password_user/1 sets reset_password_token and reset_password_token_expires_at" do
      user = Factory.create_user()
      {:ok, user} = Accounts.reset_password_user(user)

      assert not is_nil(user.reset_password_token)
      assert not is_nil(user.reset_password_token_expires_at)
    end

    test "get_user_by_reset_password_token!/1 returns a user by reset_password_token" do
      user = Factory.create_user()
      {:ok, user} = Accounts.reset_password_user(user)

      assert user == Accounts.get_user_by_reset_password_token!(user.reset_password_token)
    end

    test "update_user_password/2 " do
      user = Factory.create_user()
      {:ok, user} = Accounts.reset_password_user(user)

      assert user == Accounts.get_user_by_reset_password_token!(user.reset_password_token)
    end

    test "update_user_password/2 with valid data updates the user" do
      user = Factory.create_user()
      {:ok, user} = Accounts.reset_password_user(user)
      assert {:ok, updated_user} = Accounts.update_user_password(user, %{password: "a password"})

      assert is_nil(updated_user.reset_password_token)
      assert is_nil(updated_user.reset_password_token_expires_at)
      assert user.password_hash != updated_user.password_hash
      assert not is_nil(updated_user.password_hash)
    end

    test "update_user_password/2 with invalid data returns error changeset" do
      user = Factory.create_user()
      {:ok, user} = Accounts.reset_password_user(user)
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user_password(user, %{password: ""})
      assert user == Accounts.get_user!(user.id)
    end

    test "create_login_user_action/2 creates user_action" do
      user = Factory.create_user()
      naive_datetime = NaiveDateTime.utc_now()
      {:ok, %{event: "login"}} = Accounts.create_login_user_action(user, naive_datetime)
      {:ok, %{event: "login"}} = Accounts.create_login_user_action(user)
    end

    test "create_reset_password_user_action/2 creates user_action" do
      user = Factory.create_user()
      naive_datetime = NaiveDateTime.utc_now()

      {:ok, %{event: "reset_password"}} =
        Accounts.create_reset_password_user_action(user, naive_datetime)

      {:ok, %{event: "reset_password"}} = Accounts.create_reset_password_user_action(user)
    end

    test "create_session_refresh_user_action/2 creates user_action" do
      user = Factory.create_user()
      naive_datetime = NaiveDateTime.utc_now()

      {:ok, %{event: "session_refresh"}} =
        Accounts.create_session_refresh_user_action(user, naive_datetime)

      {:ok, %{event: "session_refresh"}} = Accounts.create_session_refresh_user_action(user)
    end

    test "User.name works with complete name" do
      user = Factory.create_user(first_name: "John", last_name: "Smith")
      assert User.name(user) == "John Smith"
    end

    test "User.name works with missing first and last name" do
      user = Factory.create_user(first_name: nil, last_name: nil)
      assert User.name(user) == ""
    end

    test "User.name works with missing first name" do
      user = Factory.create_user(first_name: nil, last_name: "Smith")
      assert User.name(user) == "Smith"
    end

    test "User.name works with missing last name" do
      user = Factory.create_user(first_name: "John", last_name: nil)
      assert User.name(user) == "John"
    end

    test "User.timezone prefers timezone over timezone_device" do
      user =
        Factory.create_user(timezone: "Canada/Newfoundland", timezone_device: "Canada/Atlantic")

      assert User.timezone(user) == "Canada/Newfoundland"
    end

    test "User.timezone works with missing timezone" do
      user = Factory.create_user(timezone: nil, timezone_device: "Canada/Atlantic")
      assert User.timezone(user) == "Canada/Atlantic"
    end

    test "User.timezone works with missing timezone and missing timezone_device" do
      user = Factory.create_user(timezone: nil, timezone_device: nil)
      assert User.timezone(user) == "Etc/UTC"
    end

    test "User.timezone uses timezone_argyle when all others are missing" do
      user =
        Factory.create_user(
          timezone: nil,
          timezone_device: nil,
          timezone_argyle: "Canada/Atlantic"
        )

      assert User.timezone(user) == "Canada/Atlantic"
    end

    test "User.working_day_bounds applies timezone shifting" do
      user = Factory.create_user(timezone: "America/Chicago")
      date = ~D[2021-10-31]

      beginning = DateTime.new!(~D[2021-10-31], ~T[09:00:00], "Etc/UTC")
      ending = DateTime.new!(~D[2021-11-01], ~T[09:00:00], "Etc/UTC")

      assert [beginning, ending] == User.working_day_bounds(date, user)

      # this is a typical working day, 24 hours long
      assert DateTime.diff(ending, beginning) == 24 * 60 * 60
    end

    test "User.working_day_bounds handles DST" do
      user = Factory.create_user(timezone: "America/Chicago")
      date = ~D[2021-11-06]

      beginning = DateTime.new!(~D[2021-11-06], ~T[09:00:00], "Etc/UTC")
      ending = DateTime.new!(~D[2021-11-07], ~T[10:00:00], "Etc/UTC")

      assert [beginning, ending] == User.working_day_bounds(date, user)

      # this is extra long due to DST
      assert DateTime.diff(ending, beginning) == 25 * 60 * 60
    end

    test "User.get_next_working_day_boundary" do
      user = Factory.create_user(timezone: "America/Chicago")

      assert ~U[2021-10-31 09:00:00Z] ==
               User.get_next_working_day_boundary(~U[2021-10-31 04:00:00Z], user)

      assert ~U[2021-11-01 09:00:00Z] ==
               User.get_next_working_day_boundary(~U[2021-10-31 09:00:00Z], user)

      assert ~U[2021-11-01 09:00:00Z] ==
               User.get_next_working_day_boundary(~U[2021-10-31 09:01:00Z], user)
    end

    test "User.datetime_to_working_day works with UTC timezone" do
      user = Factory.create_user(timezone: nil)

      datetime1 = DateTime.from_naive!(~N[2021-11-15 03:59:59], "Etc/UTC")
      assert User.datetime_to_working_day(datetime1, user) == ~D[2021-11-14]

      datetime2 = DateTime.from_naive!(~N[2021-11-15 04:00:00], "Etc/UTC")
      assert User.datetime_to_working_day(datetime2, user) == ~D[2021-11-15]

      datetime3 = DateTime.from_naive!(~N[2021-11-15 04:00:01], "Etc/UTC")
      assert User.datetime_to_working_day(datetime3, user) == ~D[2021-11-15]
    end

    test "User.datetime_to_working_day works with mismatched timezone" do
      user = Factory.create_user(timezone: "America/Chicago")

      datetime1 = DateTime.from_naive!(~N[2021-11-15 09:59:59], "Etc/UTC")
      assert User.datetime_to_working_day(datetime1, user) == ~D[2021-11-14]

      datetime2 = DateTime.from_naive!(~N[2021-11-15 10:00:00], "Etc/UTC")
      assert User.datetime_to_working_day(datetime2, user) == ~D[2021-11-15]

      datetime3 = DateTime.from_naive!(~N[2021-11-15 10:00:01], "Etc/UTC")
      assert User.datetime_to_working_day(datetime3, user) == ~D[2021-11-15]
    end

    test "User.datetime_to_working_day works with potentially ambigious dates" do
      user = Factory.create_user(timezone: "America/Chicago")

      # this is a datetime in the middle of when DST is switching over
      {:ambiguous, dt1, dt2} = DateTime.from_naive(~N[2021-11-07 01:30:00], "America/Chicago")
      dt1 = dt1 |> DateTime.shift_zone!("Etc/UTC")
      dt2 = dt2 |> DateTime.shift_zone!("Etc/UTC")

      assert User.datetime_to_working_day(dt1, user) == ~D[2021-11-06]
      assert User.datetime_to_working_day(dt2, user) == ~D[2021-11-06]
    end

    test "User.remind_shift_start works with notification and shift settings" do
      for opt_out_push <- [true, false],
          deleted <- [true, false],
          remind_shift_start <- [true, false],
          remind_shift_end <- [true, false] do
        user =
          Factory.create_user(%{
            deleted: deleted,
            remind_shift_start: remind_shift_start,
            remind_shift_end: remind_shift_end,
            opted_out_of_push_notifications: opt_out_push
          })

        expected = !opt_out_push and !deleted and remind_shift_start

        actual = User.can_receive_start_shift_notification(user)

        assert(
          expected == actual,
          "deleted = #{deleted}, opt_out_push = #{opt_out_push}, remind_start = #{remind_shift_start}, remind_end = #{remind_shift_end}.  Should be #{expected}, was #{actual}"
        )
      end
    end

    test "User.remind_shift_end works with notification and shift settings" do
      for opt_out_push <- [true, false],
          deleted <- [true, false],
          remind_shift_start <- [true, false],
          remind_shift_end <- [true, false] do
        user =
          Factory.create_user(%{
            deleted: deleted,
            remind_shift_start: remind_shift_start,
            remind_shift_end: remind_shift_end,
            opted_out_of_push_notifications: opt_out_push
          })

        expected = !opt_out_push and !deleted and remind_shift_end

        actual = User.can_receive_end_shift_notification(user)

        assert(
          expected == actual,
          "deleted = #{deleted}, opt_out_push = #{opt_out_push}, remind_start = #{remind_shift_start}, remind_end = #{remind_shift_end}.  Should be #{expected}, was #{actual}"
        )
      end
    end

    test "list_users_where_any_shift_reminder_enabled works with various settings" do
      for opt_out_push <- [true, false],
          deleted <- [true, false],
          remind_shift_start <- [true, false],
          remind_shift_end <- [true, false] do
        Factory.create_user(%{
          deleted: deleted,
          remind_shift_start: remind_shift_start,
          remind_shift_end: remind_shift_end,
          opted_out_of_push_notifications: opt_out_push
        })
      end

      expected =
        Accounts.list_users()
        |> Enum.filter(fn u ->
          !u.deleted and !u.opted_out_of_push_notifications and
            (u.remind_shift_start or u.remind_shift_end)
        end)
        |> Enum.sort_by(fn u -> u.id end)

      actual =
        Accounts.list_users_where_any_shift_reminder_enabled()
        |> Enum.sort_by(fn u -> u.id end)

      assert expected == actual
    end

    test "filter_non_prod_users_query works as expected" do
      non_prod_user_1 =
        Factory.create_user(%{
          email: "test1@driversseat.co"
        }).id

      non_prod_user_2 =
        Factory.create_user(%{
          email: "test2@DriversSeat.co"
        }).id

      non_prod_user_3 =
        Factory.create_user(%{
          email: "test2@acme.co",
          is_demo_account: true
        }).id

      prod_user_1 =
        Factory.create_user(%{
          email: "test@acme.co"
        }).id

      non_prod_users =
        Accounts.get_users_query()
        |> Accounts.filter_non_prod_users_query(true)
        |> select([u], u.id)
        |> Repo.all()
        |> Enum.sort()

      prod_users =
        Accounts.get_users_query()
        |> Accounts.filter_non_prod_users_query(false)
        |> select([u], u.id)
        |> Repo.all()
        |> Enum.sort()

      assert non_prod_users == [non_prod_user_1, non_prod_user_2, non_prod_user_3]
      assert prod_users == [prod_user_1]
    end
  end
end
