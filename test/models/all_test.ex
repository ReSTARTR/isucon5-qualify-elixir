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
