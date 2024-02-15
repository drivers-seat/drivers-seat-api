defmodule DriversSeatCoopWeb.Mailer do
  use Swoosh.Mailer, otp_app: :dsc

  def from_email_name do
    Application.get_env(:dsc, DriversSeatCoopWeb.Mailer)[:from_name]
  end

  def from_email_address do
    Application.get_env(:dsc, DriversSeatCoopWeb.Mailer)[:from_address]
  end
end
