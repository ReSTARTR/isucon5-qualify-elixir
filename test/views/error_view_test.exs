defmodule Isucon5q.ErrorViewTest do
  use Isucon5q.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(Isucon5q.ErrorView, "404.html", []) ==
           "Page not found"
  end

  test "render 500.html" do
    assert render_to_string(Isucon5q.ErrorView, "500.html", []) ==
           "Server internal error"
  end

  test "render any other" do
    assert render_to_string(Isucon5q.ErrorView, "505.html", []) ==
           "Server internal error"
  end
end
