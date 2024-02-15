defmodule DriversSeatCoopWeb.ArgyleUserControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true
  use Oban.Testing, repo: DriversSeatCoop.Repo

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.ArgyleTestClient
  alias DriversSeatCoop.Argyle.Oban.{BackfillArgyleActivities, ImportArgyleProfileInformation}

  @create_attrs %{
    argyle_id: "id",
    user_token: "token",
    accounts: %{
      "doordash" => "017eb202-4ede-293f-41c4-28f5ebe1ffa7"
    }
  }

  @update_attrs %{
    argyle_id: "updated_id",
    user_token: "updated_token",
    accounts: %{
      "uber" => "222eb202-4ede-293f-41c4-28f5ebe1ffa7"
    }
  }

  defp argyle_get_linked_accounts_resp(argyle_user_id, employer, account_id, is_connected) do
    employer = "#{employer}"

    connection =
      if is_connected do
        %{
          "error_code" => nil,
          "error_message" => nil,
          "status" => "connected",
          "updated_at" => "2023-06-09T16:11:19.675350Z"
        }
      else
        %{
          "error_code" => "error",
          "error_message" => "error",
          "status" => "error",
          "updated_at" => "2023-06-09T16:11:19.675350Z"
        }
      end

    %{
      "availability" => %{
        "activities" => %{
          "available_count" => 1856,
          "available_from" => "2019-09-09T02:57:19Z",
          "available_to" => "2023-07-07T19:23:47Z",
          "status" => "synced",
          "updated_at" => "2023-07-07T22:15:17.986888Z"
        },
        "documents" => %{
          "status" => "synced",
          "updated_at" => "2023-07-07T22:15:17.986888Z"
        },
        "employments" => %{
          "status" => "synced",
          "updated_at" => "2023-07-07T22:15:17.986888Z"
        },
        "finances" => %{
          "status" => "synced",
          "updated_at" => "2023-07-07T22:15:17.986888Z"
        },
        "forms" => nil,
        "payouts" => %{
          "available_count" => 1654,
          "available_from" => "2020-02-14T19:25:34Z",
          "available_to" => "2023-07-07T21:07:07Z",
          "status" => "synced",
          "updated_at" => "2023-07-07T22:15:18Z"
        },
        "profiles" => %{
          "status" => "synced",
          "updated_at" => "2023-07-07T22:15:17.986888Z"
        },
        "reputations" => %{
          "status" => "synced",
          "updated_at" => "2023-07-07T22:15:17.986888Z"
        },
        "vehicles" => %{
          "status" => "synced",
          "updated_at" => "2023-07-07T22:15:17.986888Z"
        }
      },
      "connection" => connection,
      "created_at" => "2023-06-09T16:09:24.885293Z",
      "data_partner" => employer,
      "employers" => [employer],
      "error_code" => if(is_connected, do: "connected", else: "error"),
      "id" => account_id,
      "item" => account_id,
      "link_item" => employer,
      "source" => employer,
      "status" => "done",
      "updated_at" => "2023-07-07T22:15:18.578925Z",
      "user" => argyle_user_id,
      "was_connected" => is_connected
    }
  end

  @argyle_vehicle_resp %{
    "count" => 2,
    "results" => [
      %{
        "created_at" => "2019-11-29T09:00:16.384575Z",
        "make" => "make",
        "model" => "model",
        "year" => 2020,
        "type" => "car"
      },
      %{
        "created_at" => "2015-11-29T09:00:16.384575Z",
        "make" => "make",
        "model" => "model",
        "year" => 2020,
        "type" => "car"
      }
    ]
  }

  @argyle_profile_resp %{
    "count" => 2,
    "results" => [
      %{
        "created_at" => "2019-11-29T09:00:16.384575Z",
        "gender" => "gender",
        "address" => %{
          "country" => "country",
          "postal_code" => "postal_code"
        }
      },
      %{
        "created_at" => "2015-11-29T09:00:16.384575Z",
        "gender" => "gender",
        "address" => %{
          "country" => "country",
          "postal_code" => "postal_code"
        }
      }
    ]
  }

  setup_all do
    DriversSeatCoop.ArgyleTestClient.init()
    Application.put_env(:dsc, :argyle_client, DriversSeatCoop.ArgyleTestClient)

    on_exit(fn ->
      Application.put_env(:dsc, :argyle_client, DriversSeatCoop.Argyle)
    end)

    :ok
  end

  setup %{conn: conn} do
    user = Factory.create_user()

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> Plug.Conn.assign(:user, user)
      |> TestHelpers.put_auth_header(user)

    on_exit(fn ->
      ArgyleTestClient.cleanup()
    end)

    {:ok, user: user, conn: conn}
  end

  describe "create argyle user" do
    test "renders argyle user when data is valid", %{conn: conn, user: user} do
      ArgyleTestClient.should_see(
        {:update_user_token, [@create_attrs.argyle_id, %{}]},
        %{
          argyle_user_id: @create_attrs.argyle_id,
          argyle_token: @create_attrs.user_token
        }
      )

      ArgyleTestClient.should_see(
        {:get_linked_accounts, [@create_attrs.argyle_id, %{}]},
        [
          argyle_get_linked_accounts_resp(@create_attrs.argyle_id, "doordash", "doordashId", true)
        ]
      )

      conn =
        post(conn, Routes.argyle_user_path(conn, :create, id: user.id),
          argyle_user: %{
            accounts: @create_attrs.accounts,
            argyle_id: @create_attrs.argyle_id,
            user_id: user.id,
            user_token: "ignored token"
          }
        )

      assert_enqueued(worker: BackfillArgyleActivities, args: %{user_id: user.id})
      assert_enqueued(worker: ImportArgyleProfileInformation, args: %{user_id: user.id})
      Oban.drain_queue(queue: :argyle_api)

      assert %{
               "accounts" => %{"doordash" => "doordashId"},
               "argyle_id" => @create_attrs.argyle_id,
               "argyle_terms_accepted_at" => nil,
               "service_names" => ["doordash"],
               "user_id" => user.id,
               "user_token" => "token"
             } == json_response(conn, 200)["data"]

      assert ArgyleTestClient.saw_everything?() == true
    end

    test "renders original user when user tries to create another user", %{conn: conn, user: user} do
      user =
        Factory.create_user_with_argyle_fields(%{
          user_id: user.id,
          argyle_user_id: @create_attrs.argyle_id
        })

      ArgyleTestClient.should_see(
        {:update_user_token, [@create_attrs.argyle_id, %{}]},
        %{
          argyle_user_id: @create_attrs.argyle_id,
          argyle_token: @create_attrs.user_token
        }
      )

      ArgyleTestClient.should_see(
        {:get_linked_accounts, [user.argyle_user_id, %{}]},
        [
          argyle_get_linked_accounts_resp(user.argyle_user_id, "uber", "uberAcctId", true)
        ]
      )

      conn =
        post(conn, Routes.argyle_user_path(conn, :create, id: user.id),
          argyle_user: %{
            accounts: @update_attrs.accounts,
            argyle_id: @update_attrs.argyle_id,
            user_id: user.id,
            user_token: @update_attrs.user_token
          }
        )

      assert %{
               "accounts" => %{
                 "uber" => "uberAcctId"
               },
               "argyle_id" => user.argyle_user_id,
               "argyle_terms_accepted_at" => nil,
               "user_id" => user.id,
               "user_token" => user.argyle_token,
               "service_names" => ["uber"]
             } == json_response(conn, 200)["data"]
    end
  end

  describe "show argyle user" do
    test "shows user", %{conn: conn, user: user} do
      user =
        Factory.create_user_with_argyle_fields(%{
          user_id: user.id,
          argyle_user_id: @create_attrs.argyle_id
        })

      ArgyleTestClient.should_see(
        {:update_user_token, [@create_attrs.argyle_id, %{}]},
        %{
          argyle_user_id: @create_attrs.argyle_id,
          argyle_token: @create_attrs.user_token
        }
      )

      linked_acct_resp =
        Enum.map(Map.to_list(@create_attrs.accounts), fn {emp, acct} ->
          argyle_get_linked_accounts_resp(user.argyle_user_id, "#{emp}", acct, true)
        end)

      ArgyleTestClient.should_see(
        {:get_linked_accounts, [user.argyle_user_id, %{}]},
        linked_acct_resp
      )

      conn = get(conn, Routes.argyle_user_path(conn, :show, user.id))

      assert %{
               "accounts" => @create_attrs.accounts,
               "argyle_id" => @create_attrs.argyle_id,
               "argyle_terms_accepted_at" => nil,
               "user_id" => user.id,
               "user_token" => @create_attrs.user_token,
               "service_names" => Map.keys(@create_attrs.accounts)
             } == json_response(conn, 200)["data"]
    end

    test "creates argyle user if not already set up", %{conn: conn, user: user} do
      ArgyleTestClient.should_see(
        {:create, [%{}, %{}]},
        %{
          argyle_user_id: @create_attrs.argyle_id,
          argyle_token: @create_attrs.user_token
        }
      )

      linked_acct_resp =
        Enum.map(Map.to_list(@create_attrs.accounts), fn {emp, acct} ->
          argyle_get_linked_accounts_resp(@create_attrs.argyle_id, "#{emp}", acct, true)
        end)

      ArgyleTestClient.should_see(
        {:get_linked_accounts, [@create_attrs.argyle_id, %{}]},
        linked_acct_resp
      )

      conn = get(conn, Routes.argyle_user_path(conn, :show, user.id))

      assert %{
               "accounts" => @create_attrs.accounts,
               "argyle_id" => @create_attrs.argyle_id,
               "argyle_terms_accepted_at" => nil,
               "user_id" => user.id,
               "user_token" => @create_attrs.user_token,
               "service_names" => Map.keys(@create_attrs.accounts)
             } == json_response(conn, 200)["data"]
    end
  end

  describe "update argyle user" do
    test "ignores info on update request and gets info from argyle", %{conn: conn, user: user} do
      ArgyleTestClient.should_see(
        {:profiles, [@create_attrs.argyle_id, %{}]},
        @argyle_profile_resp
      )

      ArgyleTestClient.should_see(
        {:vehicles, [@create_attrs.argyle_id, %{}]},
        @argyle_vehicle_resp
      )

      ArgyleTestClient.should_see(
        {:get_linked_accounts, [@create_attrs.argyle_id, %{}]},
        [
          argyle_get_linked_accounts_resp(@create_attrs.argyle_id, "doordash", "doordashId", true)
        ]
      )

      user = Factory.create_user_with_argyle_fields(%{user_id: user.id, service_names: nil})

      conn =
        put(conn, Routes.argyle_user_path(conn, :update, user.id),
          argyle_user: %{
            accounts: @update_attrs.accounts,
            argyle_id: @update_attrs.argyle_id,
            service_names: ["grubhub", "doordash"],
            user_id: user.id,
            user_token: @update_attrs.user_token
          }
        )

      assert_enqueued(worker: BackfillArgyleActivities, args: %{user_id: user.id})
      assert_enqueued(worker: ImportArgyleProfileInformation, args: %{user_id: user.id})
      Oban.drain_queue(queue: :argyle_api)

      assert %{
               "accounts" => %{"doordash" => "doordashId"},
               "argyle_id" => @create_attrs.argyle_id,
               "argyle_terms_accepted_at" => nil,
               "service_names" => ["doordash"],
               "user_id" => user.id,
               "user_token" => "token"
             } == json_response(conn, 200)["data"]

      user = Accounts.get_user!(user.id)

      assert user.vehicle_make_argyle == "make"
      assert user.gender_argyle == "gender"
      assert user.vehicle_year_argyle == 2020
      assert user.postal_code_argyle == "postal_code"
      assert ArgyleTestClient.saw_everything?() == true
    end

    test "does not clear service_names when they are not supplied on input (backward compatibility)",
         %{conn: conn, user: user} do
      user =
        Factory.create_user_with_argyle_fields(%{
          user_id: user.id,
          argyle_user_id: @create_attrs.argyle_id,
          service_names: ["doordash"],
          argyle_accounts: %{
            doordash: "doordashId"
          }
        })

      ArgyleTestClient.should_see(
        {:get_linked_accounts, [@create_attrs.argyle_id, %{}]},
        [
          argyle_get_linked_accounts_resp(@create_attrs.argyle_id, "doordash", "doordashId", true)
        ]
      )

      conn =
        put(conn, Routes.argyle_user_path(conn, :update, user.id),
          argyle_user: %{
            accounts: @update_attrs.accounts,
            argyle_id: @update_attrs.argyle_id,
            user_id: user.id,
            user_token: @update_attrs.user_token
          }
        )

      assert %{
               "accounts" => %{"doordash" => "doordashId"},
               "argyle_id" => user.argyle_user_id,
               "argyle_terms_accepted_at" => nil,
               "service_names" => ["doordash"],
               "user_id" => user.id,
               "user_token" => user.argyle_token
             } == json_response(conn, 200)["data"]
    end
  end

  describe "delete argyle_user" do
    test "deletes chosen argyle_user", %{conn: conn, user: user} do
      user = Factory.create_user_with_argyle_fields(%{user_id: user.id})

      ArgyleTestClient.should_see(
        {:delete, [user.argyle_user_id, %{}]},
        {:ok, nil}
      )

      conn = delete(conn, Routes.argyle_user_path(conn, :delete, user.id))
      res = json_response(conn, 200)["data"]

      assert res["argyle_id"] == user.argyle_user_id

      user = Accounts.get_user!(user.id)

      assert user.argyle_accounts == nil
      assert user.argyle_token == nil
      assert user.argyle_user_id == nil
      assert ArgyleTestClient.saw_everything?() == true
    end
  end
end
