class Hemlock < Formula
  desc "A small, unsafe language for writing unsafe things safely"
  homepage "https://github.com/hemlang/hemlock"
  url "https://github.com/hemlang/hemlock/archive/refs/tags/v1.8.8.tar.gz"
  sha256 "eb48bc2ca8e2535d384741ba225daabe3ea726e03c1b4e04233b08c0e68f9594"
  license "MIT"
  head "https://github.com/hemlang/hemlock.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

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
