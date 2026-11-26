class Hpm < Formula
  desc "Package manager for the Hemlock programming language"
  homepage "https://github.com/hemlang/hpm"
  url "https://github.com/hemlang/hpm/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "e221e78d50b411b552ce6b6ff7f7e0e76956d3cc87b7f77901b561e326616289"
  license "MIT"
  head "https://github.com/hemlang/hpm.git", branch: "main"

  depends_on "hemlang/tap/hemlock"

  def install
    # Upstream's `make install` writes a wrapper that execs
    # "$(CURDIR)/src/main.hml", i.e. the temporary build directory, which
    # Homebrew deletes after install. Ship the sources in libexec and point
    # the wrapper there (and at hemlock's opt path, not whatever is on PATH).
    libexec.install "src"
    (bin/"hpm").write <<~SH
      #!/bin/sh
      exec "#{Formula["hemlang/tap/hemlock"].opt_bin}/hemlock" "#{libexec}/src/main.hml" "$@"
    SH
    chmod 0755, bin/"hpm"
  end

  test do
    assert_match "hpm v#{version}", shell_output("#{bin}/hpm --version")

    system bin/"hpm", "init", "--yes"
    assert_path_exists testpath/"package.json"
    assert_match "\"version\": \"0.1.0\"", (testpath/"package.json").read
  end
end
