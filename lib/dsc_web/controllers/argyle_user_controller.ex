defmodule DriversSeatCoopWeb.ArgyleUserController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Argyle
  alias DriversSeatCoop.Argyle.Oban.BackfillArgyleActivities
  alias DriversSeatCoop.Argyle.Oban.ImportArgyleProfileInformation
  alias DriversSeatCoop.GigAccounts
  alias DriversSeatCoopWeb.ArgyleUserValidator

  plug DriversSeatCoopWeb.AuthenticationPlug
  action_fallback DriversSeatCoopWeb.FallbackController

  def show(conn, _) do
    with {:ok, user} <- Argyle.get_or_update(conn.assigns.user) do
      conn
      |> assign(:user, user)
      |> handle_gig_account_update()
    end
  end

  def update(conn, _), do: handle_gig_account_update(conn)

  def create(conn, params) do
    with {:ok, attrs} <- ArgyleUserValidator.create(params) do
      with {:ok, user} <- Argyle.get_or_update(conn.assigns.user, attrs.argyle_id) do
        conn
        |> assign(:user, user)
        |> handle_gig_account_update()
      end
    end
  end

  defp handle_gig_account_update(conn) do
    with {:ok, change_status} <- GigAccounts.refresh_user_gig_accounts(conn.assigns.user) do
      user = Accounts.get_user!(conn.assigns.user.id)
      conn = assign(conn, :user, user)

      if change_status == :has_changes do
        {:ok, _} = BackfillArgyleActivities.schedule_job(user.id)
        {:ok, _} = ImportArgyleProfileInformation.schedule_job(user.id)
      end

      render(conn, "show.json", argyle_user: user)
    end
  end

  def delete(conn, _) do
    user = conn.assigns.user

    case Argyle.delete_argyle_user(user.argyle_user_id) do
      {:error, _} ->
        Sentry.capture_message("failed to delete argyle user",
          extra: %{user_id: conn.assigns.user.id}
        )

      _ ->
        # remove our reference to the argyle user, now that they have been
        # deleted from argyle
        {:ok, user} =
          Accounts.update_user(user, %{
            argyle_accounts: nil,
            argyle_token: nil,
            argyle_user_id: nil
          })

        {:ok, _} = GigAccounts.refresh_user_gig_accounts(user)
    end

    # user still holds the old argyle related fields
    render(conn, "show.json", argyle_user: user)
  end
end
