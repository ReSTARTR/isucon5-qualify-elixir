defmodule Isucon5q.PageControllerTest do
  use Isucon5q.ConnCase

  test "GET /" do
    conn = get conn(), "/"
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
