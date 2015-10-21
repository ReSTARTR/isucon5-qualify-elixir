defmodule Isucon5q.Repo do
  use Ecto.Repo, otp_app: :isucon5q

  def filter_while(collection, f, count) do
    collection
    |> Stream.filter(f)
    |> Stream.with_index
    |> Stream.take_while(fn {e, i} -> i < count end)
    |> Stream.map(fn {e, i} -> e end)
  end
end
