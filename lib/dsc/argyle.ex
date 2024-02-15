defmodule DriversSeatCoop.Argyle do
  @moduledoc """
  Functions for interacting with the Argyle API
  """

  @behaviour DriversSeatCoop.ArgyleClient

  alias DriversSeatCoop.{Accounts, Driving}
  alias DriversSeatCoop.Accounts.User
  require Logger

  defp get_all_activities(opts) do
    opts = Map.merge(opts, %{limit: 200})

    argyle_url("activities", opts)
    |> paginate_stream()
  end

  def delete_argyle_user(id) do
    client().delete(id)
  end

  @impl true
  def get_linked_accounts(argyle_user_id) do
    url =
      argyle_url("accounts", %{
        user: argyle_user_id,
        limit: 200
      })

    get_linked_accounts_impl(url)
  end

  # Handles pagination
  defp get_linked_accounts_impl(url) do
    {:ok, response} = request(:get, url)

    accounts = get_in(response, ["results"]) || []
    next_page_url = get_in(response, ["next"])

    if is_nil(next_page_url) do
      {:ok, accounts}
    else
      with {:ok, next_page_accounts} <- get_linked_accounts_impl(get_in(response, ["next"])) do
        {:ok, accounts ++ next_page_accounts}
      end
    end
  end

  @impl true
  def delete(argyle_account_id) do
    url = argyle_url("users/#{argyle_account_id}", %{})

    case request(:delete, url) do
      {:ok, _} -> {:ok, :deleted}
      {:error, 404, _} -> {:ok, :not_found}
      x -> x
    end
  end

  def get_gig_accounts(%User{} = user) do
    if is_nil(user.argyle_user_id),
      do: {:ok, []},
      else: client().get_linked_accounts(user.argyle_user_id)
  end

  def get_or_update(%User{} = user, argyle_user_id \\ nil) do
    {:ok, argyle_user_info} =
      if is_nil(user.argyle_user_id) and is_nil(argyle_user_id),
        do: client().create(),
        else: client().update_user_token(user.argyle_user_id || argyle_user_id)

    Accounts.update_user(user, argyle_user_info)
  end

  @impl true
  def create do
    url = argyle_url("users", %{})
    header = [{"Content-Type", "application/json"}]

    case request(:post, url, "", header) do
      {:ok, response} ->
        argyle_info = %{
          argyle_user_id: response["id"],
          argyle_token: response["token"] || response["user_token"] || response["access"]
        }

        {:ok, argyle_info}

      {:error, error} ->
        Logger.error("failed to create new argyle user #{inspect(error)}")
        {:error, error}
    end
  end

  @impl true
  def update_user_token(argyle_user_id) do
    url = argyle_url("user-tokens", %{})
    body = Jason.encode!(%{user: argyle_user_id})
    header = [{"Content-Type", "application/json"}]

    case request(:post, url, body, header) do
      {:ok, response} ->
        {:ok,
         %{
           argyle_user_id: argyle_user_id,
           argyle_token: response["token"] || response["user_token"] || response["access"]
         }}

      {:error, error} ->
        Logger.error(
          "failed to update argyle user token for argyle user #{argyle_user_id}: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  @doc """
  Fetch activities from the Argyle API and insert them into the database.
  Operation can be limited by account ID, from_start_date, to_start_date, etc.

  This function will return a list of Argyle activity ids that have been
  upserted.
  """
  def backfill_argyle_activities(%User{} = user, opts \\ %{}) do
    opts = %{user: user.argyle_user_id} |> Enum.into(opts)

    get_all_activities(opts)
    |> Stream.filter(fn
      {:error, err} -> raise RuntimeError, message: err
      _activity -> true
    end)
    |> Stream.map(fn activity ->
      {:ok, %{activity_id: activity_id}} = Driving.upsert_activity(activity, user.id)
      activity_id
    end)
    |> Enum.to_list()
  end

  def refresh_argyle_user_tokens(%User{} = user) do
    case update_user_token(user) do
      {:ok, return} ->
        Accounts.update_user(user, return)

      {:error, error} ->
        # TODO Invalid PK: Is hit when user does not exist in ARGYLE, so use
        # this error to remove that argyle_user from our DB
        # Or find other reasons why this would error and what errors
        Logger.error("failed to get new user token from argyle #{inspect(error)}")
    end
  end

  @doc """
  Get the expiration DateTime given token in UTC. If the token is already
  expired or invalid then the expiration DateTime is now.
  """
  def get_token_expiration(nil), do: DateTime.utc_now()

  def get_token_expiration(token) do
    with [_, body | _] <- String.split(token, "."),
         {:ok, decoded_body} <- Base.decode64(body),
         {:ok, json} <- Jason.decode(decoded_body),
         %{"exp" => expiration_timestamp} <- json do
      DateTime.from_unix!(expiration_timestamp)
    else
      _ -> DateTime.utc_now()
    end
  end

  @impl true
  def vehicles(user_id, opts \\ %{}) do
    opts = Map.merge(%{user: user_id}, opts)
    url = argyle_url("vehicles", opts)
    request(:get, url)
  end

  @impl true
  def profiles(user_id, opts \\ %{}) do
    opts = Map.merge(%{user: user_id}, opts)
    url = argyle_url("profiles", opts)
    request(:get, url)
  end

  def import_argyle_profile_information(%User{} = user) do
    user_data = %{}

    user_data =
      case client().vehicles(user.argyle_user_id) do
        {:ok, %{"results" => vehicles}} ->
          car =
            vehicles
            |> Enum.filter(fn v -> v["type"] == "car" end)
            |> find_newest("created_at")

          Map.merge(user_data, %{
            vehicle_make_argyle: car["make"],
            vehicle_model_argyle: car["model"],
            vehicle_year_argyle: car["year"]
          })

        {:error, error} ->
          Sentry.capture_message("No Vehicles for #{user.id} #{inspect(error)}")
          user_data
      end

    user_data =
      case client().profiles(user.argyle_user_id) do
        {:ok, %{"results" => profiles}} ->
          profile = find_newest(profiles, "created_at")

          Map.merge(user_data, %{
            country_argyle: profile["address"]["country"],
            postal_code_argyle: profile["address"]["postal_code"],
            gender_argyle: profile["gender"]
          })

        {:error, error} ->
          Sentry.capture_message("No Profile for #{user.id} #{inspect(error)}")
          user_data
      end

    Accounts.update_user(user, user_data)
  end

  defp find_newest([], _) do
    nil
  end

  defp find_newest(list, field) do
    list
    |> Enum.sort_by(
      fn v ->
        NaiveDateTime.from_iso8601!(v[field])
      end,
      {:desc, NaiveDateTime}
    )
    |> hd()
  end

  # Will return a stream which will paginated the argyle response.
  defp paginate_stream(initial_url) do
    Stream.resource(
      fn -> initial_url end,
      fn
        nil ->
          {:halt, nil}

        url ->
          case request(:get, url) do
            {:ok, %{"next" => next_url, "results" => results}} -> {results, next_url}
            e -> {[e], nil}
          end
      end,
      fn _ -> :ok end
    )
  end

  defp argyle_url(path, opts) do
    path = String.trim_leading(path, "/")
    env = Application.get_env(:dsc, DriversSeatCoop.Argyle)
    "#{env[:url]}#{path}?#{URI.encode_query(opts)}"
  end

  defp client do
    Application.get_env(:dsc, :argyle_client)
  end

  # credo:disable-for-next-line
  def request(method, url, body \\ [], header \\ []) do
    env = Application.get_env(:dsc, DriversSeatCoop.Argyle)

    client_id = env[:client_id] || ""
    client_secret = env[:client_secret] || ""

    {:ok, response} =
      HTTPoison.request(method, url, body, header,
        hackney: [basic_auth: {client_id, client_secret}]
      )

    response =
      case Map.get(response, :body) do
        nil -> Map.put(response, :body, "{}")
        "" -> Map.put(response, :body, "{}")
        _ -> response
      end

    response_body =
      case Map.get(response, :body) do
        x when x in [nil, ""] -> {:ok, nil}
        body_json -> Jason.decode(body_json)
      end

    case {response.status_code, response_body} do
      # overloaded, retry
      {429, _} ->
        Process.sleep(:rand.uniform(500))
        request(method, url)

      # response is good, body was parsed ok
      {status, {:ok, body}} when status in 200..299 ->
        {:ok, body}

      {status, {:ok, body}} ->
        {:error, status, body}

      {status, body} ->
        {:error, status, body}
    end
  end
end
