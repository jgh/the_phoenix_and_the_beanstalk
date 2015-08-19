defmodule ThePhoenixAndTheBeanstalk.PageController do
  use ThePhoenixAndTheBeanstalk.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
