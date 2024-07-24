defmodule PlantAidWeb.PageController do
  use PlantAidWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def about(conn, _params) do
    render(conn, :about)
  end

  def funding(conn, _params) do
    render(conn, :funding)
  end

  def contact(conn, _params) do
    render(conn, :contact)
  end

  def publications(conn, _params) do
    render(conn, :publications)
  end

  def team(conn, _params) do
    render(conn, :team)
  end

  def pathogens(conn, _params) do
    render(conn, :pathogens)
  end

  def tools(conn, _params) do
    render(conn, :tools)
  end
end
