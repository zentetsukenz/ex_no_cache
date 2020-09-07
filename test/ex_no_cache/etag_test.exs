defmodule ExNoCache.ETagTest do
  use ExUnit.Case, async: true

  alias ExNoCache.ETag

  describe "generate/1" do
    test "generates etag when term is binary" do
      {:ok, etag} = ETag.generate("dead men tell no tales")

      assert "5510ae4a413cb3aaaa986510edb5d49400f23dc59621aeb18fa6851d9d169315" == etag
    end

    test "generates etag when term is iolist" do
      one = "one"
      {:ok, etag} = ETag.generate([one, "for", "a", "l", "l"])

      assert "14ec0f2931dbe5d765c4a8a78327fe8c032d3007939ad2eef3caa13640eff94a" == etag
    end
  end
end
