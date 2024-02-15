defmodule DriversSeatCoopWeb.ReferralSourceController do
  use DriversSeatCoopWeb, :controller
  alias DriversSeatCoop.ReferralSources
  alias DriversSeatCoopWeb.ReferralSourceValidator

  action_fallback DriversSeatCoopWeb.FallbackController

  def index(conn, _params) do
    referral_sources = ReferralSources.list_referral_sources(conn.assigns.user.id)
    render(conn, "index.json", referral_sources: referral_sources)
  end

  def lookup(conn, %{"code" => referral_code}) do
    ReferralSources.get_referral_source(referral_code)
    |> case do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(DriversSeatCoopWeb.ErrorView)
        |> render(:"404")

      referral_source ->
        render(conn, "show.json", referral_source: referral_source)
    end
  end

  def show(conn, params) do
    with {:ok, params} <- ReferralSourceValidator.show(params) do
      with {:ok, referral_source} <-
             ReferralSources.create_or_generate_referral_source(
               params.referral_type,
               conn.assigns.user.id
             ) do
        render(conn, "show.json", referral_source: referral_source)
      end
    end
  end
end
