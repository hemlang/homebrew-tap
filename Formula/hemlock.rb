class Hemlock < Formula
  desc "A small, unsafe language for writing unsafe things safely"
  homepage "https://github.com/hemlang/hemlock"
  url "https://github.com/hemlang/hemlock/archive/refs/tags/v1.7.0.tar.gz"
  sha256 "b53383d23b26ac6677db74b0a3b71196e7359c53e3f226cd7f6d3dfa305a93ed"
  license "MIT"
  head "https://github.com/hemlang/hemlock.git", branch: "main"

  depends_on "libffi"
  depends_on "openssl@3"
  depends_on "libwebsockets"

  def install
    ENV["PREFIX"] = prefix
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"hello.hem").write <<~HEM
      println("Hello, World!")
    HEM
    assert_match "Hello, World!", shell_output("#{bin}/hemlock #{testpath}/hello.hem")
  end
end
