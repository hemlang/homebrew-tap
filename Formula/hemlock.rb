class Hemlock < Formula
  desc "A small, unsafe language for writing unsafe things safely"
  homepage "https://github.com/hemlang/hemlock"
  url "https://github.com/hemlang/hemlock/archive/refs/tags/v2.16.1.tar.gz"
  sha256 "0b996decd1c9ccc53860c108a0e45916fbb08ce3f516e7002fe8035adedb2a0a"
  license "MIT"
  head "https://github.com/hemlang/hemlock.git", branch: "main"

  depends_on "pkgconf" => :build
  depends_on "libffi"
  depends_on "openssl@3"
  depends_on "libwebsockets"

  uses_from_macos "zlib"

  def install
    # PREFIX must be visible to the build step too: the Makefile bakes
    # $(PREFIX)/lib/hemlock into hemlockc (-DHEMLOCK_LIBDIR) at compile time.
    ENV["PREFIX"] = prefix
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"hello.hml").write <<~HML
      print("Hello, World!");
    HML
    assert_match "Hello, World!", shell_output("#{bin}/hemlock #{testpath}/hello.hml")

    # Confirms the stdlib was installed where the interpreter looks for it.
    (testpath/"hash.hml").write <<~HML
      import { sha256 } from "@stdlib/hash";
      print(sha256("abc"));
    HML
    assert_match "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
                 shell_output("#{bin}/hemlock #{testpath}/hash.hml")
  end
end
