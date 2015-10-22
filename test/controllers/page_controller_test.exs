defmodule Isucon5q.PageControllerTest do
  use Isucon5q.ConnCase

  # Document:
  #   http://hexdocs.pm/phoenix/Phoenix.ConnTest.html

  setup_all do
    :ok # do nothing
  end

  setup context do
    if context[:authorized] do
      # TODO: Setup authorized session
    end
    :ok
  end

  test "GET /initialize" do
    conn = get conn(), "/initialize"
    assert text_response(conn, 200) == ""
  end

  test "GET /" do
    conn = get conn(), "/"
    assert redirected_to(conn, 302) == "/login"
  end

  test "GET /login" do
    conn = get conn(), "/login"
    assert html_response(conn, 200) =~ "<h2>ISUxi login</h2>"
  end

  test "GET /logout" do
    conn = get conn(), "/logout"
    assert redirected_to(conn, 302) == "/login"
  end

  # @tag :authorized
  # test "GET /" do
  #  conn = get conn(), "/"
  #  assert html_response(conn, 200) == "<html>"
  # end
end
