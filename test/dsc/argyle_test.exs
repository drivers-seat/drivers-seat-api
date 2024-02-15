defmodule DriversSeatCoop.ArgyleTest do
  use DriversSeatCoop.DataCase, async: false

  require Logger

  alias DriversSeatCoop.Argyle

  describe "get_token_expiration" do
    test "works with nil token" do
      expiration = Argyle.get_token_expiration(nil)
      now = DateTime.utc_now()
      assert DateTime.diff(expiration, now) <= 1
    end

    test "works with blank token" do
      expiration = Argyle.get_token_expiration("")
      now = DateTime.utc_now()
      assert DateTime.diff(expiration, now) <= 1
    end

    test "works with a malformed token" do
      expiration = Argyle.get_token_expiration("abc.def.ghi")
      now = DateTime.utc_now()
      assert DateTime.diff(expiration, now) <= 1
    end

    test "works with a valid token" do
      token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjbGllbnRfaWQiOiJjZDA2YWM5Mi0xNDA4LTQ2MzYtODcwNS00ZGYwM2QzYjVjMjYiLCJleHAiOjE2Mjg3ODczODcsImlhdCI6MTYyNjE5NTM4NywiaXNzIjoiYXJneWxlLWNvcmUtYXV0aC1wcm9kIiwianRpIjoiYmFiNmYzYzAtMzFmNS00NGFlLWI1M2UtOWJhMDIxMmQzOTFlIiwic3ViIjoiMDE3YWEwY2MtNjRmMS1jZWIzLTNiMWEtYTg3ZDU1OWMwMjg0IiwidXNlcl9pZCI6IjAxN2FhMGNjLTY0ZjEtY2ViMy0zYjFhLWE4N2Q1NTljMDI4NCJ9.lDMXVLqTw4iKxGkEVg-QI0YO7PMsXsBfI8z0t2bpZeg"

      assert Argyle.get_token_expiration(token) == ~U[2021-08-12 16:56:27Z]
    end
  end
end
