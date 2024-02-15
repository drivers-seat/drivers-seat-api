defmodule DriversSeatCoopWeb.MarketingController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop
  alias DriversSeatCoop.Marketing
  alias DriversSeatCoop.Marketing.Campaign
  alias DriversSeatCoop.Marketing.CampaignState

  require Logger

  def index(conn, _params) do
    render_available_campaigns(conn)
  end

  def present(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.MarketingValidator.present_accept_or_decline(params) do
      campaign = Map.get(params, :campaign)
      additional_data = Map.get(params, :additional_data)
      device = Map.get(conn.assigns, :dsc_device)

      Marketing.present_campaign(conn.assigns.user, device, campaign, additional_data)
      |> case do
        {:error, :campaign_not_found} ->
          conn
          |> put_status(:not_found)
          |> put_view(DriversSeatCoopWeb.ErrorView)
          |> render(:"404")

        {:ok, _} ->
          render_available_campaigns(conn)
      end
    end
  end

  def accept(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.MarketingValidator.present_accept_or_decline(params) do
      campaign = Map.get(params, :campaign)
      additional_data = Map.get(params, :additional_data)
      action_id = Map.get(params, :action_id)
      device = Map.get(conn.assigns, :dsc_device)

      Marketing.accept_campaign(conn.assigns.user, device, campaign, action_id, additional_data)
      |> case do
        {:error, :campaign_not_found} ->
          conn
          |> put_status(:not_found)
          |> put_view(DriversSeatCoopWeb.ErrorView)
          |> render(:"404")

        {:ok, _} ->
          render_available_campaigns(conn)
      end
    end
  end

  def postpone(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.MarketingValidator.postpone(params) do
      campaign = Map.get(params, :campaign)
      additional_data = Map.get(params, :additional_data)
      postpone_minutes = Map.get(params, :postpone_minutes)
      action_id = Map.get(params, :action_id)
      device = Map.get(conn.assigns, :dsc_device)

      Marketing.postpone_campaign(
        conn.assigns.user,
        device,
        campaign,
        postpone_minutes,
        action_id,
        additional_data
      )
      |> case do
        {:error, :campaign_not_found} ->
          conn
          |> put_status(:not_found)
          |> put_view(DriversSeatCoopWeb.ErrorView)
          |> render(:"404")

        {:ok, _} ->
          render_available_campaigns(conn)
      end
    end
  end

  def dismiss(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.MarketingValidator.present_accept_or_decline(params) do
      campaign = Map.get(params, :campaign)
      additional_data = Map.get(params, :additional_data)
      action_id = Map.get(params, :action_id)
      device = Map.get(conn.assigns, :dsc_device)

      Marketing.dismiss_campaign(
        conn.assigns.user,
        device,
        campaign,
        action_id,
        additional_data
      )
      |> case do
        {:error, :campaign_not_found} ->
          conn
          |> put_status(:not_found)
          |> put_view(DriversSeatCoopWeb.ErrorView)
          |> render(:"404")

        {:ok, _} ->
          render_available_campaigns(conn)
      end
    end
  end

  def save(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.MarketingValidator.save_campaign_state(params) do
      campaign = Map.get(params, :campaign)
      additional_data = Map.get(params, :additional_data)
      device = Map.get(conn.assigns, :dsc_device)

      Marketing.save_campaign_state(conn.assigns.user, device, campaign, additional_data)
      |> case do
        {:error, :campaign_not_found} ->
          conn
          |> put_status(:not_found)
          |> put_view(DriversSeatCoopWeb.ErrorView)
          |> render(:"404")

        {:ok, _} ->
          conn
          |> send_resp(:no_content, "")
      end
    end
  end

  def custom(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.MarketingValidator.present_accept_or_decline(params) do
      campaign = Map.get(params, :campaign)
      additional_data = Map.get(params, :additional_data)
      action_id = Map.get(params, :action_id)
      device = Map.get(conn.assigns, :dsc_device)

      Marketing.handle_campaign_custom_action(
        conn.assigns.user,
        device,
        campaign,
        action_id,
        additional_data
      )
      |> case do
        {:error, :campaign_not_found} ->
          conn
          |> put_status(:not_found)
          |> put_view(DriversSeatCoopWeb.ErrorView)
          |> render(:"404")

        {:ok, _} ->
          render_available_campaigns(conn)
      end
    end
  end

  defp render_available_campaigns(conn) do
    device = Map.get(conn.assigns, :dsc_device)
    user = conn.assigns.user

    configs =
      Marketing.get_available_campaigns_for_user(conn.assigns.user, device)
      |> Enum.map(fn [campaign, participant] ->
        config = Campaign.get_config(campaign, CampaignState.new(user, device, participant))

        # remove interrupt campaigns
        if user.is_demo_account do
          new_cats =
            List.wrap(Map.get(config, :categories))
            |> Enum.filter(fn cat -> cat != :interrupt end)

          Map.put(config, :categories, new_cats)
        else
          config
        end
      end)

    render(conn, "index.json", campaigns: configs)
  end
end
