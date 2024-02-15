defmodule DriversSeatCoopWeb.EmailView do
  use DriversSeatCoopWeb, :view

  alias DriversSeatCoop.Accounts.User

  def hello_greeting(%User{} = user) do
    "Hello, #{User.name(user)}"
    |> String.trim()
  end
end
