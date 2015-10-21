defmodule Isucon5q.Router do
  use Isucon5q.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Isucon5q do
    pipe_through :browser # Use the default browser stack

    get  "/",                            PageController, :index

    get  "/login",                       PageController, :login
    post "/login",                       PageController, :do_login
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

    get  "/initialize",                  PageController, :initialize
  end

  # Other scopes may use custom stacks.
  # scope "/api", Isucon5q do
  #   pipe_through :api
  # end
end
