defmodule Isucon5q.PageControllerWithSessionTest do
  use Isucon5q.ConnCase

  alias Isucon5q.Repo
  alias Isucon5q.User
  alias Isucon5q.Profile
  alias Isucon5q.Salt

  @account_name "zoe9"
  @email "zoe9@isucon.net"
  @password "zoe9"
  @salt "abcdef"

  setup do
    user = %User{account_name: @account_name, nick_name: "test", email: @email, passhash: User.gen_passhash(@password, @salt)} |> Repo.insert!
    %Salt{salt: @salt, user_id: user.id} |> Repo.insert!
    {:ok, dt} = Ecto.Date.cast("2010-01-01")
    %Profile{user_id: user.id, first_name: "test", last_name: "taro", birthday: dt, pref: "未入力", sex: "男"} |> Repo.insert!
    :ok
  end

  # Returns a Plug.Conn that has an authenticated session.
  defp session_conn do
    conn()
    |> get("/login", %{})
    |> recycle
    |> post("/login", %{"email" => @email, "password" => @password})
  end

  test "GET /" do
    conn = get session_conn(), "/"
    assert html_response(conn, 200) =~ "<!DOCTYPE html>"
  end

  test "GET /profile/:account_name" do
    conn = get session_conn(), "/profile/" <> @account_name
    assert html_response(conn, 200) =~ "<!DOCTYPE html>"
  end

  test "GET /diary/entries/:account_name" do
    conn = get session_conn(), "/diary/entries/" <> @account_name
    assert html_response(conn, 200) =~ "<!DOCTYPE html>"
  end

  test "GET /diary/entry/:entry_id" do
    conn = get session_conn(), "/diary/entry/99999"
    assert html_response(conn, 404)
  end

  test "GET /footprints" do
    conn = get session_conn(), "/footprints"
    assert html_response(conn, 200) =~ "<!DOCTYPE html>"
  end

  test "GET /friends" do
    conn = get session_conn(), "/friends"
    assert html_response(conn, 200) =~ "<!DOCTYPE html>"
  end
end
