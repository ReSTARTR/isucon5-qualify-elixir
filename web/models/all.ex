defmodule Isucon5q.User do
  use Isucon5q.Web, :model

  schema "users" do
    field :passhash
    field :account_name
    field :nick_name
    field :email

    has_one :salt, Salt, foreign_key: :user_id
  end

  def get_by(user_id: id) do
    Isucon5q.Repo.get(Isucon5q.User, id)
  end

  def get_by(account_name: account_name) do
    Isucon5q.Repo.get_by(Isucon5q.User, account_name: account_name)
  end

  def auth(email, password) do
    # NOTE: "due to its complexity, such style is discouraged."
    #   ref: http://hexdocs.pm/ecto/Ecto.Query.html
    q = from u in Isucon5q.User,
      join: s in Isucon5q.Salt, on: u.id == s.user_id,
      where: u.email == ^email and u.passhash == fragment("SHA2(CONCAT(?, salt), 512)", ^password),
      select: u

    q |> Isucon5q.Repo.one
  end
end

defmodule Isucon5q.Relation do
  use Isucon5q.Web, :model
  schema "relations" do
    field :one, :integer
    field :another, :integer

    timestamps inserted_at: :created_at, updated_at: nil
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w{one another}, ~w{})
  end

  # SELECT COUNT(1) AS cnt FROM relations WHERE (one = ? AND another = ?) OR (one = ? AND another = ?)
  def friendship(one, another) do
    from(r in Isucon5q.Relation,
      where: (r.one == ^one and r.another == ^another) or (r.one == ^another and r.another == ^one),
      order_by: [desc: :created_at],
      select: count(r.id))
    |> Isucon5q.Repo.one > 0
  end

  # SELECT * FROM relations WHERE one = ? OR another = ? ORDER BY created_at DESC
  def friends(user_id: user_id) do
    from(r in Isucon5q.Relation,
      where: r.one == ^user_id or r.another == ^user_id,
      order_by: [desc: :created_at],
      select: r)
    |> Isucon5q.Repo.all
    |> Enum.map(fn r ->
      case { r.one, r.another } do
        { ^user_id, another } -> [another, r.created_at]
        { another, ^user_id } -> [another, r.created_at]
      end
    end)
    |> Enum.reduce(Map.new, fn([id,dt], acc) -> Map.put_new(acc, id, dt) end)
    |> Enum.map(fn {id, dt} -> [id, Ecto.DateTime.to_erl(dt)] end)
    |> Enum.sort_by(fn [_, dt] -> dt end)
    |> Enum.reverse
    |> Enum.map(fn [id, _] -> id end)
  end
end

defmodule Isucon5q.Salt do
  use Isucon5q.Web, :model

  @primary_key {:user_id, :integer, []}
  @derive {Phoenix.Param, key: :user_id}
  schema "salts" do
    # field :user_id, Ecto.UUID, primary_key: true
    field :salt

    belongs_to :user, User, define_field: false
  end
end

defmodule Isucon5q.Profile do
  use Isucon5q.Web, :model

  @primary_key {:user_id, :integer, []}
  @derive {Phoenix.Param, key: :user_id}
  schema "profiles" do
    # field :user_id,   :id, primary_key: true
    field :first_name
    field :last_name
    field :sex
    field :birthday,  Ecto.Date
    field :pref

    timestamps(inserted_at: nil, updated_at: :updated_at)
    # field :updated_at, Ecto.DateTime
  end

  # ref: http://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(first_name last_name sex birthday), ~w(pref))
  end

  def get_by(user_id: user_id) do
    Isucon5q.Repo.get(Isucon5q.Profile, user_id)
  end
end

defmodule Isucon5q.Footprint do
  use Isucon5q.Web, :model
  schema "footprints" do
    field :user_id,    :integer
    field :owner_id,   :integer
    field :updated_at, Ecto.DateTime, virtual: true

    timestamps inserted_at: :created_at, updated_at: nil
  end

  # TODO:
  #   SELECT user_id, owner_id, DATE(created_at) AS date, MAX(created_at) AS updated
  #   FROM footprints
  #   WHERE user_id = ?
  #   GROUP BY user_id, owner_id, DATE(created_at)
  #   ORDER BY updated DESC
  #   LIMIT 10
  def recent_by(owner_id: owner_id, limit: limit) do
    q = from f in Isucon5q.Footprint,
        where: f.owner_id == ^owner_id,
        group_by: [f.user_id, f.owner_id, f.created_at],
        order_by: [desc: :created_at],
        limit: ^limit,
        select: [f.user_id, f.owner_id, f.created_at, fragment("? AS updated_at", max(f.created_at))]

    Isucon5q.Repo.all(q)
    |> Enum.map(fn [user_id, owner_id, created_at, updated_at] ->
      {:ok, updated_at } = updated_at |> Ecto.DateTime.cast
        %Isucon5q.Footprint{
          user_id: user_id,
          owner_id: owner_id,
          created_at: created_at,
          updated_at: updated_at,
        }
    end)
  end

  def mark(from: from, to: to) do
    params = %{ "user_id" => from, "owner_id" => to }

    %Isucon5q.Footprint{}
    |> cast(params, ~w{user_id owner_id}, ~w{})
    |> Isucon5q.Repo.insert
  end
end

defmodule Isucon5q.Entry do
  use Isucon5q.Web, :model
  schema "entries" do
    field :user_id, :integer
    field :private, :boolean
    field :body
    field :title,   :string, virtual: true
    field :content, :string, virtual: true

    timestamps(inserted_at: :created_at, updated_at: nil)

    # has_many :comments, Isucon5q.Comment, foreign_key: :entry_id, references: :id
  end

  def changeset(model, params \\ :empty) do
    data = %{
     "body" => (params["title"] || "タイトルなし") <> "\n" <> (params["content"] || ""),
     # benchmarker post as 1 if private checkbox was checked
     "private" => ~w{on 1} |> Enum.member?(params["private"]),
     "user_id" => params["user_id"],
   }
    model
    |> cast(data, ~w{user_id body}, ~w{private})
  end

  def get_by(entry_id: entry_id) do
    Isucon5q.Repo.get(Isucon5q.Entry, entry_id)
  end

  # friend:
  #   SELECT * FROM entries WHERE user_id = ? ORDER BY created_at DESC LIMIT 20
  # non-friend:
  #   SELECT * FROM entries WHERE user_id = ? AND private=0 ORDER BY created_at DESC LIMIT 20
  def recent_by(limit \\ 10, user_id: user_id, permitted: permitted) do
    q = from e in Isucon5q.Entry,
      where: e.user_id == ^user_id,
      order_by: [desc: :created_at],
      limit: ^limit,
      select: e
    if ! permitted do
       q = Ecto.Query.where(q, [e], e.private == false)
    end
    Isucon5q.Repo.all(q)
  end

  # SELECT * FROM entries ORDER BY created_at DESC LIMIT 1000
  def user_friends(user_id: user_id) do
    from(e in Isucon5q.Entry, order_by: [desc: :created_at], limit: 1000)
    |> Isucon5q.Repo.all
    |> Isucon5q.Repo.filter_while(fn (e) -> Isucon5q.Relation.friendship(user_id, e.user_id) end, 10)
    |> Enum.to_list
  end
end

defmodule Isucon5q.Comment do
  use Isucon5q.Web, :model

  schema "comments" do
    field :entry_id,   :integer
    field :user_id,    :integer
    field :comment

    timestamps inserted_at: :created_at, updated_at: nil

    # belongs_to :entry, Isucon5q.Entry, define_field: false #foreign_key: :entry_id
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w{entry_id user_id comment}, ~w{})
  end

  def get_by(entry_id: entry_id) do
    q = from c in Isucon5q.Comment,
        where: c.entry_id == ^entry_id,
        order_by: [desc: :created_at],
        select: c
    Isucon5q.Repo.all(q)
  end

  def recent_by(user_id: user_id) do
    {:ok, result} = Ecto.Adapters.SQL.query(Isucon5q.Repo,
      "SELECT c.id AS id, c.entry_id AS entry_id, c.user_id AS user_id, c.comment AS comment, c.created_at AS created_at
      FROM comments c
      JOIN entries e ON c.entry_id = e.id
      WHERE e.user_id = ?
      ORDER BY c.created_at DESC
      LIMIT 10", [user_id])
    %{columns: columns, num_rows: num_rows, rows: rows} = result

    rows |> Enum.map(&(from_list(columns, &1)))
  end

  def user_friends(user_id: user_id) do
    from(c in Isucon5q.Comment, order_by: [desc: :created_at], limit: 1000)
    |> Isucon5q.Repo.all
    |> Isucon5q.Repo.filter_while(fn (c) -> Isucon5q.Relation.friendship(user_id, c.user_id) end, 10)
    |> Enum.to_list
  end

  def from_list(columns, r) do
    fields = Enum.reduce(Enum.zip(columns, r), %{}, fn({key, value}, map) -> Map.put(map, key, value) end)
    Ecto.Schema.__load__(Isucon5q.Comment, nil, nil, [], fields, &Isucon5q.Repo.__adapter__.load/2)
  end

  def count_by(entry_id: entry_id) do
    from(c in Isucon5q.Comment, where: c.entry_id == ^entry_id, select: count(1))
    |> Isucon5q.Repo.one
  end
end

