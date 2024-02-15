defmodule DriversSeatCoop.GigAccounts do
  @moduledoc """
  The Gig Accounts context
  """
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Argyle
  alias DriversSeatCoop.GigAccounts.UserGigAccount
  alias DriversSeatCoop.Repo
  import Ecto.Query, warn: false

  def query do
    from(g in UserGigAccount,
      where: g.deleted == false
    )
  end

  def query_filter_user(qry, user_id_or_ids) do
    user_id_or_ids = List.wrap(user_id_or_ids)
    where(qry, [g], g.user_id in ^user_id_or_ids)
  end

  def query_filter_is_connected(qry, is_connected \\ true),
    do: where(qry, [g], g.is_connected == ^is_connected)

  def query_filter_argyle_id(qry, argyle_id_or_ids) do
    argyle_id_or_ids = List.wrap(argyle_id_or_ids)
    where(qry, [g], g.argyle_id in ^argyle_id_or_ids)
  end

  def query_filter_employer(qry, employer_or_employers, include \\ true) do
    employer_or_employers =
      List.wrap(employer_or_employers)
      |> Enum.map(fn e -> "#{e}" end)

    if include,
      do: where(qry, [g], g.employer in ^employer_or_employers),
      else: where(qry, [g], g.employer not in ^employer_or_employers)
  end

  def refresh_user_gig_accounts(%User{} = user) do
    {:ok, argyle_accounts} = Argyle.get_gig_accounts(user)
    update_user_gig_accounts(user, argyle_accounts)
  end

  def update_user_gig_accounts(user, argyle_gig_accounts) do
    user_id = user.id

    existing_gig_accounts =
      query()
      |> query_filter_user(user_id)
      |> Repo.all()

    new_gig_accts =
      Enum.map(argyle_gig_accounts, fn g -> get_attrs_from_argyle_gig_account(g) end)

    multi = Ecto.Multi.new()

    {multi, unmatched_gig_accounts} =
      Enum.reduce(new_gig_accts, {multi, existing_gig_accounts}, fn new_gig_acct,
                                                                    {m, remaining_gig_accts} ->
        argyle_id = Map.get(new_gig_acct, :argyle_id)

        match_gig_account = Enum.find(remaining_gig_accts, fn x -> x.argyle_id == argyle_id end)

        remaining_gig_accts = Enum.reject(remaining_gig_accts, fn x -> x == match_gig_account end)

        changeset =
          UserGigAccount.changeset(
            match_gig_account || %UserGigAccount{user_id: user_id, argyle_id: argyle_id},
            new_gig_acct
          )

        m = Ecto.Multi.insert_or_update(m, "upsert_#{argyle_id}", changeset)

        {m, remaining_gig_accts}
      end)

    multi =
      unmatched_gig_accounts
      |> Enum.filter(fn del_gig_acct -> del_gig_acct.deleted == false end)
      |> Enum.reduce(multi, fn del_gig_acct, m ->
        changeset = UserGigAccount.changeset(del_gig_acct, %{deleted: true})

        Ecto.Multi.update(m, "delete_#{del_gig_acct.argyle_id}", changeset)
      end)

    {user_changeset, change_status} = get_argyle_accounts_user_changeset(user, new_gig_accts)
    multi = Ecto.Multi.update(multi, "user", user_changeset)

    {:ok, _} = Repo.transaction(multi)
    {:ok, change_status}
  end

  defp get_argyle_accounts_user_changeset(%User{} = user, gig_accounts) do
    service_names = get_service_names(gig_accounts)
    argyle_accounts = get_argyle_accounts_map(gig_accounts)

    # reorder the service names to avoid false changes
    user = Map.put(user, :service_names, Enum.sort(user.service_names || []))

    changeset =
      User.changeset(user, %{
        service_names: service_names,
        argyle_accounts: argyle_accounts
      })

    changes =
      cond do
        Ecto.Changeset.get_change(changeset, :service_names, :not_changed) != :not_changed ->
          :has_changes

        Ecto.Changeset.get_change(changeset, :argyle_accounts, :not_changed) != :not_changed ->
          :has_changes

        true ->
          :no_changes
      end

    {changeset, changes}
  end

  defp get_argyle_accounts_map(gig_accts) do
    gig_accts =
      gig_accts
      |> Enum.filter(fn g ->
        not is_nil(Map.get(g, :employer)) and not is_nil(Map.get(g, :argyle_id))
      end)

    if Enum.any?(gig_accts) do
      Enum.reduce(gig_accts, %{}, fn g, model ->
        Map.put(model, Map.get(g, :employer), Map.get(g, :argyle_id))
      end)
    else
      nil
    end
  end

  defp get_service_names(gig_accts) do
    gig_accts
    |> Enum.filter(fn g -> Map.get(g, :is_connected) == true end)
    |> Enum.map(fn g -> Map.get(g, :employer) end)
    |> Enum.filter(fn g -> not is_nil(g) end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def get_attrs_from_argyle_gig_account(argyle_gig_account) do
    attrs = %{
      argyle_id: get_in(argyle_gig_account, ["id"]),
      employer:
        get_in(argyle_gig_account, ["source"]) ||
          get_in(argyle_gig_account, ["link_item"]) ||
          get_in(argyle_gig_account, ["data_partner"]),
      account_data: argyle_gig_account,
      deleted: false,
      connection_status: get_in(argyle_gig_account, ["connection", "status"]),
      connection_error_code: get_in(argyle_gig_account, ["connection", "error_code"]),
      connection_error_message: get_in(argyle_gig_account, ["connection", "error_message"]),
      connection_updated_at: get_in(argyle_gig_account, ["connection", "updated_at"])
    }

    activity_info =
      get_in(argyle_gig_account, ["availability", "activities"]) ||
        get_in(argyle_gig_account, ["availability", "gigs"])

    attrs =
      attrs
      |> Map.put(:activity_status, get_in(activity_info, ["status"]))
      |> Map.put(:activity_count, get_in(activity_info, ["available_count"]))
      |> Map.put(:activities_updated_at, get_in(activity_info, ["updated_at"]))
      |> Map.put(:activity_date_min, get_in(activity_info, ["available_from"]))
      |> Map.put(:activity_date_max, get_in(activity_info, ["available_to"]))

    attrs
    |> Map.put(:is_synced, Map.get(attrs, :activity_status) == "synced")
    |> Map.put(:is_connected, Map.get(attrs, :connection_status) == "connected")
    |> Map.put(
      :connection_has_errors,
      not is_nil(
        Map.get(attrs, :connection_error_code) || Map.get(attrs, :connection_error_message)
      )
    )
  end

  def has_connected_gig_account?(user_id, employer_or_employers) do
    employer_or_employers =
      List.wrap(employer_or_employers)
      |> Enum.map(fn e -> "#{e}" end)

    query()
    |> query_filter_user(user_id)
    |> query_filter_is_connected()
    |> query_filter_employer(employer_or_employers)
    |> Repo.exists?()
  end
end
