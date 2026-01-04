class Hpm < Formula
  desc "Package manager for the Hemlock programming language"
  homepage "https://github.com/hemlang/hpm"
  url "https://github.com/hemlang/hpm/archive/refs/tags/v1.0.8.tar.gz"
  sha256 "0fae5a7c6965f862e860449495c26f5749f161769fd47e4d345d9c0a547bce2a"
  license "MIT"
  head "https://github.com/hemlang/hpm.git", branch: "main"

  depends_on "hemlang/tap/hemlock"

  def install
    ENV["PREFIX"] = prefix
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_match "hpm", shell_output("#{bin}/hpm --version")
  end
end
