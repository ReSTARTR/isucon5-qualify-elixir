defmodule Isucon5q.PageController do
  use Isucon5q.Web, :controller
  require Logger

  alias Isucon5q.Repo

  alias Isucon5q.User
  alias Isucon5q.Profile
  alias Isucon5q.Entry
  alias Isucon5q.Comment
  alias Isucon5q.Relation
  alias Isucon5q.Footprint

  defp current_user(conn) do
    User.get_by(user_id: get_session(conn, :user_id))
  end

  def index(conn, _params) do
    user = current_user(conn)

    render conn, "index.html",
      user: user,
      profile: Profile.get_by(user_id: user.id),
      entries: Entry.recent_by(5, user_id: user.id, permitted: true) |> Repo.preload([:user]),
      footprints: Footprint.recent_by(owner_id: user.id, limit: 10) |> Repo.preload([:user]),
      comments: Comment.recent_by(user_id: user.id) |> Repo.preload([:user, :entry]),
      friend_entries: Entry.user_friends(user_id: user.id) |> Repo.preload([:user]),
      friend_comments: Comment.user_friends(user_id: user.id) |> Repo.preload([:user, :entry_user]),
      friends: Relation.friends(user_id: user.id)
  end

  def login(conn, _params) do
    render conn, "login.html", message: "", email: "", password: ""
  end

  def do_login(conn, %{"email" => email, "password" => password}) do
    user = User.auth(email, password)
    case user do
      nil ->
        conn
        |> put_status(400)
        |> render("login.html", message: "ログインに失敗しました", email: email, password: password)
      _ ->
        conn = put_session(conn, :user_id, user.id)
        redirect conn, to: "/"
    end
  end

  def logout(conn, _params) do
    conn = clear_session(conn)
    redirect conn, to: "/login"
  end

  def profile(conn, %{ "account_name" => account_name }) do
    user      = current_user(conn)
    owner     = User.get_by(account_name: account_name)
    profile   = Profile.get_by(user_id: owner.id)
    permitted = user.id == owner.id || Relation.friendship(user.id, owner.id)
    entries   = Entry.recent_by(user_id: owner.id, permitted: permitted)

    {:ok, _} = Footprint.mark(from: user.id, to: owner.id)

    render conn, "profile.html",
      user:      user,
      profile:   profile,
      owner:     owner,
      entries:   entries,
      permitted: permitted
  end

  def friends(conn, _params) do
    user = current_user(conn)
    friend_ids = Relation.friends(user_id: user.id)
    friends = Ecto.Query.from(u in User, where: u.id in ^friend_ids) |> Repo.all
    render conn, "friends.html", user: user, friends: friends
  end

  def friends_post(conn, %{ "account_name" => account_name }) do
    user = current_user(conn)
    owner = User.get_by(account_name: account_name)

    case Repo.transaction(fn ->
      Relation.changeset(%Relation{}, %{ "one" => owner.id, "another" => user.id}) |> Repo.insert!
      Relation.changeset(%Relation{}, %{ "one" => user.id, "another" => owner.id}) |> Repo.insert!
    end) do
      {:ok, _} ->
        redirect conn, to: "/friends"
      {:error, _} ->
        text conn, "Failed to insert relationships" # TODO:
    end
  end

  def diary_entries(conn, %{ "account_name" => account_name }) do
    user = current_user(conn)
    owner = User.get_by(account_name: account_name)
    permitted = user.id == owner.id || Relation.friendship(user.id, owner.id)
    entries = Entry.recent_by(user_id: owner.id, permitted: permitted) |> Repo.preload([:comments])

    {:ok, _} = Footprint.mark(from: user.id, to: owner.id)

    render conn, "diary_entries.html", user: user, owner: owner, entries: entries
  end

  def diary_entry(conn, %{ "entry_id" => entry_id }) do
    user = current_user(conn)
    entry = Entry.get_by(entry_id: entry_id) |> Repo.preload([:user, :comments, :comment_user])

    if entry.private && !Relation.friendship(user.id, entry.user.id) do
      conn
      |> put_status(403)
      |> text("Forbidden")
    else
      {:ok, _} = Footprint.mark(from: user.id, to: entry.user.id)

      render conn, "diary_entry.html",
        user: user,
        entry: entry
    end
  end

  def diary_comment_post(conn, %{ "entry_id" => entry_id, "comment" => comment }) do
    user = current_user(conn)
    changeset = Comment.changeset(%Comment{}, %{ "entry_id" => entry_id, "user_id" => user.id, "comment" => comment })

    case Repo.insert(changeset) do
      # TODO: status see other
      {:ok, _model} -> redirect conn, to: "/diary/entry/" <> entry_id
      # TODO: error page
      {:error, changeset} -> text(conn, List.join(changeset.errors))
    end
  end

  def diary_entry_post(conn, params) do
    user = current_user(conn)
    changeset = Entry.changeset(%Entry{}, Map.merge(params, %{ "user_id" => user.id }))

    case Repo.insert(changeset) do
      {:ok, _model} -> redirect conn, to: "/diary/entries/" <> user.account_name
      {:error, changeset} -> text(conn, List.join(changeset.errors)) # TODO: error status
    end
  end

  def footprints(conn, _params) do
    user = current_user(conn)
    footprints = Footprint.recent_by(owner_id: user.id, limit: 50) |> Repo.preload([:user])

    render conn, "footprints.html", footprints: footprints
  end

  def initialize(conn, _params) do
    [
      from(r in Relation,  where: r.id > 500000),
      from(f in Footprint, where: f.id > 500000),
      from(e in Entry,     where: e.id > 500000),
      from(c in Comment,   where: c.id > 1500000),
    ]
    |> Enum.map(fn(query) ->
      {_, nil} = query |> Repo.delete_all(timeout: 10000)
    end)

    text(conn, "")
  end

  def profile_update(conn, params) do
    user = current_user(conn)

    q = from p in Profile, where: p.user_id == ^user.id

    {_cnt, _} = Repo.update_all(q, [set: [
      first_name: params["first_name"],
      last_name:  params["last_name"],
      birthday:   params["birthday"],
      sex:        params["sex"],
      pref:       params["pref"],
    ]])

    redirect conn, to: "/profile/" <> user.account_name
  end
end
