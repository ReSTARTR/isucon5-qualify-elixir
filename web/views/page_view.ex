defmodule Isucon5q.PageView do
  use Isucon5q.Web, :view

  alias Isucon5q.Comment
  alias Isucon5q.User
  alias Isucon5q.Entry

  def prefs do
    ["未入力",
     "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県", "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県", "新潟県", "富山県",
     "石川県", "福井県", "山梨県", "長野県", "岐阜県", "静岡県", "愛知県", "三重県", "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県", "鳥取県", "島根県",
     "岡山県", "広島県", "山口県", "徳島県", "香川県", "愛媛県", "高知県", "福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"]
  end

  def friend?(one, another) do
    Isucon5q.Relation.friendship(one, another)
  end

  def user(id) do
    Isucon5q.Repo.get(User, id)
  end

  def entry(id) do
    Isucon5q.Repo.get(Entry, id)
  end

  def entry_title(%Entry{body: body}) do
    String.split(body, "\n") |> Enum.take 1
  end

  def entry_content(%Entry{body: body}) do
    String.split(body, "\n") |> Enum.slice(1..-1) |> Enum.join("\n")
  end

  def comment_digest(s) do
    if String.length(s) > 30 do
      [String.slice(s, 0, 27), "..."]
    else
      s
    end
  end

  def num_comments(entry_id) do
    Comment.count_by(entry_id: entry_id)
  end
end
