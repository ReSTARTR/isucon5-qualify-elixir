defmodule Isucon5q.PageController do
  use Isucon5q.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
