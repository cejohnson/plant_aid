defmodule PlantAidWeb.Api.V1.GeoJSON.CountyController do
  use PlantAidWeb, :controller

  alias PlantAid.Geography

  def index(conn, _params) do
    counties = Geography.list_counties()
    render(conn, :index, counties: counties)
  end
end
