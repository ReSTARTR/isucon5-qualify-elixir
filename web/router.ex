defmodule Isucon5q.Router do
  use Isucon5q.Web, :router

  def authenticate(conn, params) do
    user_id = get_session(conn, :user_id)
    if user_id == nil do
      conn
      |> put_flash(:error, "ログインしていません")
      |> redirect(to: "/login")
      |> halt
    else
      user = Isucon5q.User.get_by(user_id: user_id)
      if user == nil do
        conn
        |> put_flash(:error, "ログインに失敗しました")
        |> clear_session
        |> redirect(to: "/login")
        |> halt
      else
        conn
      end
    end
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :browser_auth do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
    plug :authenticate #Isucon5q.Plugs.Authenticator
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/login", Isucon5q do
    pipe_through :browser

    get  "/", PageController, :login
    post "/", PageController, :do_login
  end

  scope "/initialize", Isucon5q do
    pipe_through :browser

    get  "/", PageController, :initialize
  end

  scope "/", Isucon5q do
    pipe_through :browser_auth

    get  "/",                            PageController, :index

    get  "/logout",                      PageController, :logout

    get  "/profile/:account_name",       PageController, :profile
    post "/profile/:account_name",       PageController, :profile_update

    get  "/diary/entries/:account_name", PageController, :diary_entries
    post "/diary/entry",                 PageController, :diary_entry_post
    get  "/diary/entry/:entry_id",       PageController, :diary_entry
    post "/diary/comment/:entry_id",     PageController, :diary_comment_post

    get  "/footprints",                  PageController, :footprints

    get  "/friends",                     PageController, :friends
    post "/friends/:account_name",       PageController, :friends_post
  end

  # Other scopes may use custom stacks.
  # scope "/api", Isucon5q do
  #   pipe_through :api
  # end
end
