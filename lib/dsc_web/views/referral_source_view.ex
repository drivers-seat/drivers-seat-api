defmodule DriversSeatCoopWeb.ReferralSourceView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.ReferralSourceView

  def render("index.json", %{referral_sources: referral_sources}) do
    %{data: render_many(referral_sources, ReferralSourceView, "referral_source.json")}
  end

  def render("show.json", %{referral_source: referral_source}) do
    %{data: render_one(referral_source, ReferralSourceView, "referral_source.json")}
  end

  def render("referral_source.json", %{referral_source: referral_source}) do
    %{
      referral_type: referral_source.referral_type,
      referral_code: referral_source.referral_code,
      is_active: referral_source.is_active
    }
  end
end
