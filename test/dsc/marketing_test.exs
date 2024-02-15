defmodule DriversSeatCoop.MarketingTest do
  use DriversSeatCoop.DataCase, async: true
  use Oban.Testing, repo: DriversSeatCoop.Repo

  alias DriversSeatCoop.Marketing
  alias DriversSeatCoop.Marketing.CallToAction
  alias DriversSeatCoop.Marketing.Campaign
  alias DriversSeatCoop.Marketing.CampaignParticipant
  alias DriversSeatCoop.Marketing.CampaignState

  describe "set_populations_for_user" do
    test "Does not overwrite unless requested" do
      user = Factory.create_user()

      # add user to populations a, b, c
      populations =
        Marketing.set_populations_for_user(user, "test_pop_type", [:a, :b, :c], false, false)

      population_codes = Enum.map(populations, fn pop -> pop.population end) |> Enum.sort()
      assert population_codes == ["a", "b", "c"]

      # additionally, add user to population d and e
      populations =
        Marketing.set_populations_for_user(user, "test_pop_type", [:d, :e], false, false)

      population_codes = Enum.map(populations, fn pop -> pop.population end) |> Enum.sort()
      assert population_codes == ["a", "b", "c", "d", "e"]

      # additionally, re-add c and d
      populations =
        Marketing.set_populations_for_user(user, "test_pop_type", [:c, :d], false, false)

      population_codes = Enum.map(populations, fn pop -> pop.population end) |> Enum.sort()
      assert population_codes == ["a", "b", "c", "d", "e"]
    end

    test "Overwrites when requested to do so" do
      user = Factory.create_user()

      # add user to populations a, b, c
      populations =
        Marketing.set_populations_for_user(user, "test_pop_type", [:a, :b, :c], false, false)

      population_codes = Enum.map(populations, fn pop -> pop.population end) |> Enum.sort()
      assert population_codes == ["a", "b", "c"]

      # additionally, add user to population d and e
      populations =
        Marketing.set_populations_for_user(user, "test_pop_type", [:d, :e], false, true)

      population_codes = Enum.map(populations, fn pop -> pop.population end) |> Enum.sort()
      assert population_codes == ["d", "e"]

      # additionally, re-add c and d
      populations =
        Marketing.set_populations_for_user(user, "test_pop_type", [:c, :d], false, false)

      population_codes = Enum.map(populations, fn pop -> pop.population end) |> Enum.sort()
      assert population_codes == ["c", "d", "e"]
    end
  end

  describe "query campaigns" do
    test "filter by user_id" do
      test_campaigns = [test_campaign_2(), test_campaign_3()]

      u1 = Factory.create_user()
      d1 = Factory.create_device(u1.id, "DEVICE1")
      u2 = Factory.create_user()
      d2 = Factory.create_device(u2.id, "DEVICE2")
      u3 = Factory.create_user()
      d3 = Factory.create_device(u3.id, "DEVICE3")

      Marketing.present_campaign(u1, d1, test_campaign_3().id, nil, test_campaigns)
      Marketing.present_campaign(u2, d2, test_campaign_3().id, nil, test_campaigns)
      Marketing.present_campaign(u3, d3, test_campaign_3().id, nil, test_campaigns)

      actual_cps =
        Marketing.query_campaign_participation()
        |> Marketing.query_filter_user(u1.id)
        |> Repo.all()

      assert Enum.count(actual_cps) == 1
      actual_cp = Enum.at(actual_cps, 0)
      assert actual_cp.user_id == u1.id
      assert actual_cp.campaign == "#{test_campaign_3().id}"

      actual_cps =
        Marketing.query_campaign_participation()
        |> Marketing.query_filter_user([u1.id, u2.id])
        |> Repo.all()

      assert Enum.count(actual_cps) == 2
      actual_user_ids = Enum.map(actual_cps, fn cp -> cp.user_id end) |> Enum.sort()
      assert actual_user_ids == [u1.id, u2.id]
    end

    test "filter by campaign_id" do
      test_campaigns = [test_campaign_2(), test_campaign_3(), test_campaign_4()]

      u1 =
        Factory.create_user(%{
          first_name: "FirstName",
          last_name: "LastName"
        })

      d1 = Factory.create_device(u1.id, "DEVICE1")
      u2 = Factory.create_user()
      d2 = Factory.create_device(u2.id, "DEVICE2")
      u3 = Factory.create_user()
      d3 = Factory.create_device(u3.id, "DEVICE3")

      Marketing.present_campaign(u1, d1, test_campaign_3().id, nil, test_campaigns)
      Marketing.present_campaign(u1, d1, test_campaign_4().id, nil, test_campaigns)

      Marketing.present_campaign(u2, d2, test_campaign_3().id, nil, test_campaigns)

      Marketing.present_campaign(u3, d3, test_campaign_3().id, nil, test_campaigns)

      actual_cps =
        Marketing.query_campaign_participation()
        |> Marketing.query_filter_campaign(test_campaign_4().id)
        |> Repo.all()

      assert Enum.count(actual_cps) == 1
      actual_cp = Enum.at(actual_cps, 0)
      assert actual_cp.user_id == u1.id
      assert actual_cp.campaign == "#{test_campaign_4().id}"
    end

    test "filer accepted" do
      test_campaigns = [test_campaign_3(), test_campaign_4()]

      u1 = Factory.create_user()
      d1 = Factory.create_device(u1.id, "DEVICE1")
      u2 = Factory.create_user()
      d2 = Factory.create_device(u2.id, "DEVICE2")

      Marketing.present_campaign(u1, d1, test_campaign_3().id, nil, test_campaigns)
      Marketing.present_campaign(u2, d2, test_campaign_3().id, nil, test_campaigns)
      Marketing.present_campaign(u1, d1, test_campaign_4().id, nil, test_campaigns)
      Marketing.present_campaign(u2, d2, test_campaign_4().id, nil, test_campaigns)

      Marketing.accept_campaign(
        u1,
        d1,
        test_campaign_4().id,
        "default",
        nil,
        test_campaigns
      )

      actual_accepted_cps =
        Marketing.query_campaign_participation()
        |> Marketing.query_filter_accepted(true)
        |> Repo.all()

      assert Enum.count(actual_accepted_cps) == 1
      actual_accepted_cp = Enum.at(actual_accepted_cps, 0)
      assert actual_accepted_cp.user_id == u1.id
      assert actual_accepted_cp.campaign == "#{test_campaign_4().id}"

      actual_not_accepted_cps =
        Marketing.query_campaign_participation()
        |> Marketing.query_filter_accepted(false)
        |> Repo.all()

      assert Enum.count(actual_not_accepted_cps) == 3

      test_find =
        Enum.find(actual_not_accepted_cps, fn cp ->
          cp.user_id == u1.id and cp.campaign == test_campaign_4().id
        end)

      assert test_find == nil
    end

    test "filter dismissed" do
      test_campaigns = [test_campaign_3(), test_campaign_4()]

      u1 = Factory.create_user()
      d1 = Factory.create_device(u1.id, "DEVICE1")
      u2 = Factory.create_user()
      d2 = Factory.create_device(u2.id, "DEVICE2")

      Marketing.present_campaign(u1, d1, test_campaign_3().id, nil, test_campaigns)
      Marketing.present_campaign(u2, d2, test_campaign_3().id, nil, test_campaigns)
      Marketing.present_campaign(u1, d1, test_campaign_4().id, nil, test_campaigns)
      Marketing.present_campaign(u2, d2, test_campaign_4().id, nil, test_campaigns)

      Marketing.accept_campaign(
        u1,
        d1,
        test_campaign_4().id,
        "default",
        nil,
        test_campaigns
      )

      Marketing.postpone_campaign(
        u1,
        d1,
        test_campaign_3().id,
        32,
        "default",
        nil,
        test_campaigns
      )

      Marketing.dismiss_campaign(
        u1,
        d1,
        test_campaign_3().id,
        "default",
        nil,
        test_campaigns
      )

      actual_dismissed_cps =
        Marketing.query_campaign_participation()
        |> Marketing.query_filter_dismissed(true)
        |> Repo.all()

      assert Enum.count(actual_dismissed_cps) == 1
      actual_dismissed_cp = Enum.at(actual_dismissed_cps, 0)
      assert actual_dismissed_cp.user_id == u1.id
      assert actual_dismissed_cp.campaign == "#{test_campaign_3().id}"

      actual_not_dismissed_cps =
        Marketing.query_campaign_participation()
        |> Marketing.query_filter_dismissed(false)
        |> Repo.all()

      assert Enum.count(actual_not_dismissed_cps) == 3

      test_find =
        Enum.find(actual_not_dismissed_cps, fn cp ->
          cp.user_id == u1.id and cp.campaign == "#{test_campaign_3().id}"
        end)

      assert test_find == nil
    end

    test "filter postponed" do
      test_campaigns = [test_campaign_3(), test_campaign_4()]

      u1 = Factory.create_user()
      d1 = Factory.create_device(u1.id, "DEVICE1")
      u2 = Factory.create_user()
      d2 = Factory.create_device(u2.id, "DEVICE2")

      Marketing.present_campaign(u1, d1, test_campaign_3().id, nil, test_campaigns)
      Marketing.present_campaign(u2, d2, test_campaign_3().id, nil, test_campaigns)
      Marketing.present_campaign(u1, d1, test_campaign_4().id, nil, test_campaigns)
      Marketing.present_campaign(u2, d2, test_campaign_4().id, nil, test_campaigns)

      Marketing.postpone_campaign(
        u1,
        d1,
        test_campaign_4().id,
        32,
        "default",
        nil,
        test_campaigns
      )

      Marketing.accept_campaign(
        u1,
        d1,
        test_campaign_4().id,
        "default",
        nil,
        test_campaigns
      )

      Marketing.postpone_campaign(
        u1,
        d1,
        test_campaign_3().id,
        32,
        "default",
        nil,
        test_campaigns
      )

      Marketing.dismiss_campaign(
        u1,
        d1,
        test_campaign_3().id,
        "default",
        nil,
        test_campaigns
      )

      Marketing.postpone_campaign(
        u2,
        d2,
        test_campaign_3().id,
        32,
        "default",
        nil,
        test_campaigns
      )

      actual_postponed_cps =
        Marketing.query_campaign_participation()
        |> Marketing.query_filter_postponed(true)
        |> Repo.all()

      assert Enum.count(actual_postponed_cps) == 1
      actual_postponed_cp = Enum.at(actual_postponed_cps, 0)
      assert actual_postponed_cp.user_id == u2.id
      assert actual_postponed_cp.campaign == "#{test_campaign_3().id}"

      actual_not_postponed_cps =
        Marketing.query_campaign_participation()
        |> Marketing.query_filter_postponed(false)
        |> Repo.all()

      assert Enum.count(actual_not_postponed_cps) == 1

      test_find =
        Enum.find(actual_not_postponed_cps, fn cp ->
          cp.user_id == u2.id and cp.campaign == "#{test_campaign_3().id}"
        end)

      assert test_find == nil
    end
  end

  describe "campaign definitions" do
    test "all campaigns render in all states" do
      u =
        Factory.create_user(%{
          first_name: "FirstName",
          last_name: "LastName"
        })

      d = Factory.create_device(u.id, "u1_d1", %{app_version: "3.0.1"})

      participant = %CampaignParticipant{
        user_id: u.id
      }

      participants = [
        participant,
        participant
        |> Map.put(:presented_on_first, DateTime.utc_now())
        |> Map.put(:presented_on_last, DateTime.utc_now()),
        participant
        |> Map.put(:presented_on_first, DateTime.utc_now())
        |> Map.put(:presented_on_last, DateTime.utc_now())
        |> Map.put(:accepted_on, DateTime.utc_now())
        |> Map.put(:accepted_action, "accepted"),
        participant
        |> Map.put(:presented_on_first, DateTime.utc_now())
        |> Map.put(:presented_on_last, DateTime.utc_now())
        |> Map.put(:postponed_until, DateTime.utc_now())
        |> Map.put(:postponed_action, "postponed"),
        participant
        |> Map.put(:presented_on_first, DateTime.utc_now())
        |> Map.put(:presented_on_last, DateTime.utc_now())
        |> Map.put(:dismissed_on, DateTime.utc_now())
        |> Map.put(:dismissed_action, "dismissed")
      ]

      for campaign <- Marketing.get_active_campaigns() do
        for participant <- participants do
          participant = Map.put(participant, :campaign, campaign.id)
          state = CampaignState.new(u, d, participant)
          config = Campaign.get_config(campaign, state)

          config_json = Jason.encode(config)

          assert config_json != nil
        end
      end
    end

    test "can present" do
      u =
        Factory.create_user(%{
          first_name: "FirstName",
          last_name: "LastName"
        })

      d = Factory.create_device(u.id, "u1_d1", %{app_version: "3.0.1"})

      for campaign <- Marketing.get_active_campaigns() do
        {:ok, participant} = Marketing.present_campaign(u, d, campaign.id, %{})
        assert participant.user_id == u.id
        assert participant.campaign == "#{campaign.id}"
        assert participant.presented_on_first != nil
        assert participant.presented_on_last != nil
        assert participant.postponed_action == nil
        assert participant.postponed_until == nil
        assert participant.accepted_on == nil
        assert participant.accepted_action == nil
        assert participant.dismissed_on == nil
        assert participant.dismissed_action == nil
      end
    end

    test "can postpone" do
      u =
        Factory.create_user(%{
          first_name: "FirstName",
          last_name: "LastName"
        })

      d = Factory.create_device(u.id, "u1_d1", %{app_version: "3.0.1"})

      for campaign <- Marketing.get_active_campaigns() do
        now = DateTime.utc_now()

        {:ok, participant} = Marketing.postpone_campaign(u, d, campaign.id, 30, "postpone", %{})
        assert participant.user_id == u.id
        assert participant.campaign == "#{campaign.id}"
        assert participant.accepted_on == nil
        assert participant.accepted_action == nil
        assert participant.postponed_until != nil
        assert_in_delta(DateTime.diff(participant.postponed_until, now), 1790, 1810)
        assert participant.postponed_action == "postpone"
        assert participant.dismissed_on == nil
        assert participant.dismissed_action == nil
      end
    end

    test "can accept" do
      u =
        Factory.create_user(%{
          first_name: "FirstName",
          last_name: "LastName"
        })

      d = Factory.create_device(u.id, "u1_d1", %{app_version: "3.0.1"})

      for campaign <- Marketing.get_active_campaigns() do
        {:ok, participant} = Marketing.accept_campaign(u, d, campaign.id, "accept", %{})
        assert participant.user_id == u.id
        assert participant.campaign == "#{campaign.id}"
        assert participant.presented_on_first == nil
        assert participant.presented_on_last == nil
        assert participant.postponed_action == nil
        assert participant.postponed_until == nil
        assert participant.accepted_on != nil
        assert participant.accepted_action == "accept"
        assert participant.dismissed_on == nil
        assert participant.dismissed_action == nil
      end
    end

    test "can dismiss" do
      u =
        Factory.create_user(%{
          first_name: "FirstName",
          last_name: "LastName"
        })

      d = Factory.create_device(u.id, "u1_d1", %{app_version: "3.0.1"})

      for campaign <- Marketing.get_active_campaigns() do
        {:ok, participant} = Marketing.dismiss_campaign(u, d, campaign.id, "dismiss", %{})
        assert participant.user_id == u.id
        assert participant.campaign == "#{campaign.id}"
        assert participant.presented_on_first == nil
        assert participant.presented_on_last == nil
        assert participant.postponed_action == nil
        assert participant.postponed_until == nil
        assert participant.accepted_on == nil
        assert participant.accepted_action == nil
        assert participant.dismissed_on != nil
        assert participant.dismissed_action == "dismiss"
      end
    end

    test "can save state" do
      u =
        Factory.create_user(%{
          first_name: "FirstName",
          last_name: "LastName"
        })

      d = Factory.create_device(u.id, "u1_d1", %{app_version: "3.0.1"})

      for campaign <- Marketing.get_active_campaigns() do
        state = %{
          test: 3
        }

        {:ok, participant} = Marketing.save_campaign_state(u, d, campaign.id, state)
        assert participant.user_id == u.id
        assert participant.campaign == "#{campaign.id}"
        assert participant.presented_on_first == nil
        assert participant.presented_on_last == nil
        assert participant.postponed_action == nil
        assert participant.postponed_until == nil
        assert participant.accepted_on == nil
        assert participant.accepted_action == nil
        assert participant.dismissed_on == nil
        assert participant.dismissed_action == nil
        assert participant.additional_data == state
      end
    end

    test "can call custom action" do
      u =
        Factory.create_user(%{
          first_name: "FirstName",
          last_name: "LastName"
        })

      d = Factory.create_device(u.id, "u1_d1", %{app_version: "3.0.1"})

      for campaign <- Marketing.get_active_campaigns() do
        state = %{
          test: 3
        }

        {:ok, participant} =
          Marketing.handle_campaign_custom_action(u, d, campaign.id, "custom_action", state)

        assert participant.user_id == u.id
        assert participant.campaign == "#{campaign.id}"
        assert participant.presented_on_first == nil
        assert participant.presented_on_last == nil
        assert participant.postponed_action == nil
        assert participant.postponed_until == nil
        assert participant.accepted_on == nil
        assert participant.accepted_action == nil
        assert participant.dismissed_on == nil
        assert participant.dismissed_action == nil
        assert participant.additional_data == state
      end
    end

    test "campaign status is rendered properly" do
      u =
        Factory.create_user(%{
          first_name: "FirstName",
          last_name: "LastName"
        })

      d = Factory.create_device(u.id, "u1_d1", %{app_version: "3.0.1"})

      participant = %CampaignParticipant{
        user_id: u.id
      }

      participants = [
        participant,
        participant
        |> Map.put(:presented_on_first, DateTime.utc_now())
        |> Map.put(:presented_on_last, DateTime.utc_now()),
        participant
        |> Map.put(:accepted_on, DateTime.utc_now())
        |> Map.put(:accepted_action, "accepted"),
        participant
        |> Map.put(:postponed_until, DateTime.add(DateTime.utc_now(), -30 * 60, :second))
        |> Map.put(:postponed_action, "postponed"),
        participant
        |> Map.put(:postponed_until, DateTime.add(DateTime.utc_now(), 30 * 60, :second))
        |> Map.put(:postponed_action, "postponed"),
        participant
        |> Map.put(:dismissed_on, DateTime.utc_now())
        |> Map.put(:dismissed_action, "dismissed")
      ]

      for campaign <- Marketing.get_active_campaigns() do
        for participant <- participants do
          participant = Map.put(participant, :campaign, campaign.id)
          state = CampaignState.new(u, d, participant)
          config = Campaign.get_config(campaign, state)

          cond do
            participant.dismissed_on != nil ->
              assert config.status == :dismissed
              assert config.dismissed_on != nil
              assert config.postponed_until == nil
              assert config.accepted_on == nil
              assert config.presented_on == nil

            participant.accepted_on != nil ->
              assert config.status == :accepted
              assert config.accepted_on != nil
              assert config.postponed_until == nil
              assert config.dismissed_on == nil
              assert config.presented_on == nil

            participant.postponed_until != nil and
                DateTime.compare(DateTime.utc_now(), participant.postponed_until) == :lt ->
              assert config.status == :postponed
              assert config.postponed_until != nil
              assert config.accepted_on == nil
              assert config.dismissed_on == nil
              assert config.presented_on == nil

            participant.postponed_until != nil and
                DateTime.compare(DateTime.utc_now(), participant.postponed_until) in [:gt, :eq] ->
              assert config.status == :new
              assert config.postponed_until == nil
              assert config.accepted_on == nil
              assert config.dismissed_on == nil
              assert config.presented_on == nil

            participant.presented_on_first != nil ->
              assert config.status == :presented
              assert config.presented_on != nil
              assert config.postponed_until == nil
              assert config.accepted_on == nil
              assert config.dismissed_on == nil

            true ->
              assert config.status == :new
              assert config.presented_on == nil
              assert config.postponed_until == nil
              assert config.accepted_on == nil
              assert config.dismissed_on == nil
          end
        end
      end
    end
  end

  describe "get_available_campaigns_for_user" do
    test "honors version restrictions and is_qualified" do
      test_campaigns = [test_campaign_1(), test_campaign_2()]

      u1 =
        Factory.create_user(%{
          first_name: "FirstName",
          last_name: "LastName"
        })

      u1_d1 = Factory.create_device(u1.id, "u1_d1", %{app_version: "3.0.1"})
      u1_d2 = Factory.create_device(u1.id, "u1_d2", %{app_version: "3.0.0"})
      u1_d3 = Factory.create_device(u1.id, "u1_d3", %{app_version: "5.0.0"})
      u1_d4 = Factory.create_device(u1.id, "u1_d4", %{app_version: "3.6.0"})
      u1_d5 = Factory.create_device(u1.id, "u1_d5", %{app_version: "6.0.0"})

      actual_u1_d1 = Marketing.get_available_campaigns_for_user(u1, u1_d1, test_campaigns)
      actual_u1_d2 = Marketing.get_available_campaigns_for_user(u1, u1_d2, test_campaigns)
      actual_u1_d3 = Marketing.get_available_campaigns_for_user(u1, u1_d3, test_campaigns)
      actual_u1_d4 = Marketing.get_available_campaigns_for_user(u1, u1_d4, test_campaigns)
      actual_u1_d5 = Marketing.get_available_campaigns_for_user(u1, u1_d5, test_campaigns)

      assert Enum.empty?(actual_u1_d1) == true
      assert Enum.empty?(actual_u1_d2) == true

      assert Enum.count(actual_u1_d3) == 1
      [campaign, _] = Enum.at(actual_u1_d3, 0)
      assert campaign == test_campaign_1()

      assert Enum.count(actual_u1_d4) == 1
      [campaign, _] = Enum.at(actual_u1_d4, 0)
      assert campaign == test_campaign_1()

      assert Enum.empty?(actual_u1_d5) == true
    end
  end

  defp test_campaign_1 do
    CallToAction.new(:campaign1)
    |> Campaign.with_category(:test_campaign1)
    |> Campaign.include_app_version(">= 3.0.1")
    |> Campaign.include_app_version(">= 4.0.0")
    |> Campaign.exclude_app_version("< 3.5.0")
    |> Campaign.exclude_app_version(">= 6.0.0")
  end

  defp test_campaign_2 do
    CallToAction.new(:test_campaign2)
    |> Campaign.with_category(:interrupt)
    |> Campaign.is_qualified(false)
  end

  defp test_campaign_3 do
    CallToAction.new(:test_campaign3)
    |> Campaign.with_category(:interrupt)
  end

  defp test_campaign_4 do
    CallToAction.new(:test_campaign4)
    |> Campaign.with_category(:interrupt)
  end
end
