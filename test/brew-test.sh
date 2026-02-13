#!/bin/bash
# brew-test.sh — Validate and test Homebrew tap formulas locally.
#
# Usage:
#   ./test/brew-test.sh              # Run all checks
#   ./test/brew-test.sh hemlock      # Check a specific formula
#   ./test/brew-test.sh --install    # Full install + test cycle
#
# Prerequisites: Homebrew installed, tap added via:
#   brew tap hemlang/homebrew-tap <path-to-this-repo>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FORMULA_DIR="$TAP_DIR/Formula"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
else
  GREEN=''; RED=''; YELLOW=''; NC=''
fi

pass() { echo -e "${GREEN}PASS${NC}: $1"; }
fail() { echo -e "${RED}FAIL${NC}: $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "${YELLOW}WARN${NC}: $1"; }
info() { echo "---- $1"; }

ERRORS=0
DO_INSTALL=false
TARGET_FORMULA=""

for arg in "$@"; do
  case "$arg" in
    --install) DO_INSTALL=true ;;
    *)         TARGET_FORMULA="$arg" ;;
  esac
done

# ---------------------------------------------------------------
# 1. Verify SHA256 hashes match the actual upstream tarballs
# ---------------------------------------------------------------
verify_sha256() {
  local formula_file="$1"
  local name
  name="$(basename "$formula_file" .rb)"
  info "Verifying SHA256 for $name"

  local url sha256_expected
  url=$(grep -E '^\s+url "' "$formula_file" | head -1 | sed 's/.*url "//;s/"//')
  sha256_expected=$(grep -E '^\s+sha256 "' "$formula_file" | head -1 | sed 's/.*sha256 "//;s/"//')

  if [ -z "$url" ] || [ -z "$sha256_expected" ]; then
    warn "$name: Could not extract url or sha256 from formula"
    return
  fi

  local sha256_actual
  sha256_actual=$(curl -sL "$url" | sha256sum | awk '{print $1}')

  if [ "$sha256_expected" = "$sha256_actual" ]; then
    pass "$name: SHA256 matches ($sha256_expected)"
  else
    fail "$name: SHA256 mismatch!"
    echo "       Expected: $sha256_expected"
    echo "       Actual:   $sha256_actual"
  fi
}

# ---------------------------------------------------------------
# 2. Run brew audit (syntax, style, best practices)
# ---------------------------------------------------------------
run_audit() {
  local formula_file="$1"
  local name
  name="$(basename "$formula_file" .rb)"
  info "Running brew audit on $name"

  if ! command -v brew &>/dev/null; then
    warn "brew not found — skipping audit"
    return
  fi

  if brew audit --formula "$formula_file" 2>&1; then
    pass "$name: brew audit passed"
  else
    fail "$name: brew audit reported issues"
  fi
}

# ---------------------------------------------------------------
# 3. Run brew style (rubocop linting)
# ---------------------------------------------------------------
run_style() {
  local formula_file="$1"
  local name
  name="$(basename "$formula_file" .rb)"
  info "Running brew style on $name"

  if ! command -v brew &>/dev/null; then
    warn "brew not found — skipping style check"
    return
  fi

  if brew style "$formula_file" 2>&1; then
    pass "$name: brew style passed"
  else
    warn "$name: brew style reported issues (non-blocking for taps)"
  fi
}

# ---------------------------------------------------------------
# 4. Check livecheck can detect the latest version
# ---------------------------------------------------------------
run_livecheck() {
  local formula_file="$1"
  local name
  name="$(basename "$formula_file" .rb)"
  info "Running brew livecheck on $name"

  if ! command -v brew &>/dev/null; then
    warn "brew not found — skipping livecheck"
    return
  fi

  local output
  output=$(brew livecheck --formula "$formula_file" 2>&1) || true
  echo "  $output"

  if echo "$output" | grep -qE '\d+\.\d+'; then
    pass "$name: livecheck found a version"
  else
    warn "$name: livecheck did not find a version (may need tap installed)"
  fi
}

# ---------------------------------------------------------------
# 5. Full install + test cycle (--install flag)
# ---------------------------------------------------------------
run_install_test() {
  local formula_file="$1"
  local name
  name="$(basename "$formula_file" .rb)"
  info "Installing $name from source"

  if ! command -v brew &>/dev/null; then
    fail "brew not found — cannot run install test"
    return
  fi

  if brew install --build-from-source "$formula_file" 2>&1; then
    pass "$name: brew install succeeded"
  else
    fail "$name: brew install failed"
    return
  fi

  info "Running brew test on $name"
  if brew test "$name" 2>&1; then
    pass "$name: brew test passed"
  else
    fail "$name: brew test failed"
  fi
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------
echo "============================================"
echo "  Homebrew Tap Validation"
echo "============================================"
echo ""

formulas=()
if [ -n "$TARGET_FORMULA" ]; then
  f="$FORMULA_DIR/$TARGET_FORMULA.rb"
  if [ ! -f "$f" ]; then
    echo "Formula not found: $f"
    exit 1
  fi
  formulas+=("$f")
else
  for f in "$FORMULA_DIR"/*.rb; do
    formulas+=("$f")
  done
fi

for formula in "${formulas[@]}"; do
  name="$(basename "$formula" .rb)"
  echo ""
  echo "=== $name ==="
  verify_sha256 "$formula"
  run_audit "$formula"
  run_style "$formula"
  run_livecheck "$formula"
  if $DO_INSTALL; then
    run_install_test "$formula"
  fi
done

echo ""
echo "============================================"
if [ "$ERRORS" -eq 0 ]; then
  echo -e "  ${GREEN}All checks passed!${NC}"
else
  echo -e "  ${RED}$ERRORS check(s) failed.${NC}"
  exit 1
fi
