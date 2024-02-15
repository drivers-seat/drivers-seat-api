defmodule DriversSeatCoopWeb.ErrorView do
  use DriversSeatCoopWeb, :view

  def render("401.json", _assigns) do
    %{errors: %{detail: "Unauthorized"}}
  end

  def render("403.json", _assigns) do
    %{errors: %{detail: "Forbidden"}}
  end

  def render("404.json", _assigns) do
    %{errors: %{detail: "Not Found"}}
  end

  def render("451.json", %{terms: terms}) do
    %{
      errors: %{
        detail: "Unavailable For Legal Reasons. Please agree to the updated terms of service.",
        terms: %{
          id: terms.id,
          title: terms.title,
          text: terms.text
        }
      }
    }
  end

  def render("426.json", %{info: info}) do
    %{
      errors: info
    }
  end

  def render("503.json", %{info: info}) do
    %{
      errors: info
    }
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Internal Server Error"}}
  end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
