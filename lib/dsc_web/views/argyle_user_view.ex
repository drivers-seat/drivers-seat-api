defmodule DriversSeatCoopWeb.ArgyleUserView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.ArgyleUserView

  def render("show.json", %{argyle_user: user}) do
    %{data: render_one(user, ArgyleUserView, "argyle_user.json")}
  end

  def render("argyle_user.json", %{argyle_user: user}) do
    %{
      accounts: user.argyle_accounts,
      argyle_id: user.argyle_user_id,
      argyle_terms_accepted_at: nil,
      service_names: user.service_names,
      user_id: user.id,
      user_token: user.argyle_token
    }
  end
end
