defmodule Isucon5q.UserTest do
  use Isucon5q.ModelCase
  alias Isucon5q.User
  alias Isucon5q.Salt

  setup do
    password = "test"
    salt = "abcdef"

    user = %User{email: "test@isucon.net", account_name: "test", nick_name: "test", passhash: "18bf8ccec498d8a2df9e7a0eb9d4e8d6776eb04d4384777272ff36319799f5420ac749ab5bdd31279bff9206fbfd2fe414a6cc3e7823d8cb353152d513f277ce"} |> Repo.insert!
    _salt = %Salt{salt: salt, user_id: user.id} |> Repo.insert!

    # passhash = from(u in User, join: s in Salt, on: u.id == s.user_id, where: u.email == "test@isucon.net", select: fragment("SHA2(CONCAT('test', salt), 512)")) |> Repo.one

    {:ok, email: user.email, password: password}
  end

  test "auth with valid account", %{email: email, password: password} do
    user = User.auth(email, password)
    assert user != nil
    assert user.nick_name == "test"
  end

  test "auth with invalid account", %{email: email, password: password} do
    user = User.auth(email, "invalid-" <> password)
    assert user == nil
  end
end

defmodule Isucon5q.RelationTest do
  use Isucon5q.ModelCase
  alias Isucon5q.Relation

  test "valid changeset" do
    cs = Relation.changeset(%Relation{}, %{ "one" => 1, "another" => 2 })
    assert cs.valid?
  end

  test "invalid changeset" do
    cs = Relation.changeset(%Relation{}, %{})
    assert cs.valid? == false
  end

  test "friendship" do
    cs = Relation.changeset(%Relation{}, %{ "one" => 2, "another" => 99 })
    Isucon5q.Repo.insert(cs)

    assert ! Relation.friendship(1, 2)
    assert Relation.friendship(2, 99)
  end
end

defmodule Isucon5q.EntryTest do
  use Isucon5q.ModelCase
  alias Isucon5q.Entry

  test "valid changeset" do
    params = %{
      "user_id" => "1",
      "title" => nil,
      "content" => "This is entry content",
    }
    cs = Entry.changeset(%Entry{}, params)
    assert cs.valid?
    assert cs.changes.body == "タイトルなし\n" <> params["content"]
  end

  test "invalid changeset" do
    params = %{}
    assert ! Entry.changeset(%Entry{}, params).valid?
  end

  test "recent_by" do
    cs1 = Entry.changeset(%Entry{}, %{"user_id" => 9, "private" => "on", "content" => "hello"})
    cs2 = Entry.changeset(%Entry{}, %{"user_id" => 9, "private" => nil, "content" => "hello"})
    Isucon5q.Repo.insert(cs1)
    Isucon5q.Repo.insert(cs2)

    entries = Entry.recent_by(10, user_id: 9, permitted: false)
    assert !(entries |> Enum.any?(fn(e) -> e.private end))
    assert entries |> Enum.all?(fn(e) -> !e.private end)

    entries = Entry.recent_by(10, user_id: 9, permitted: true)
    assert entries |> Enum.any?(fn(e) -> e.private end)
    assert entries |> Enum.any?(fn(e) -> !e.private end)
  end
end

defmodule Isucon5q.ProfileTest do
  use Isucon5q.ModelCase
  alias Isucon5q.Profile

  test "valid changeset" do
    {:ok, dt} = Ecto.Date.cast({1990, 10, 10})
    params = %{
      "first_name" => "hello",
      "last_name" => "world",
      "sex" => "男",
      "birthday" => dt,
    }
    assert Profile.changeset(%Profile{}, params).valid?
  end

  test "invalid changeset" do
    params = %{}
    assert ! Profile.changeset(%Profile{}, params).valid?
  end
end

defmodule Isucon5q.CommentTest do
  use Isucon5q.ModelCase
  alias Isucon5q.Comment

  test "valid changeset" do
    params = %{
      entry_id: 1,
      user_id: 3,
      comment: "hello new comment",
    }
    assert Comment.changeset(%Comment{}, params).valid?
  end

  test "invalid changeset" do
    params = %{}
    assert ! Comment.changeset(%Comment{}, params).valid?
  end
end
