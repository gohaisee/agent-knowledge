#!/usr/bin/env bash
# Check runtime dependencies. On macOS, can install missing tools via Homebrew.
set -euo pipefail

INSTALL=0
if [ "${1:-}" = "--install" ]; then INSTALL=1; fi

MISSING=()

need() {
  local cmd="$1"
  local brew_pkg="${2:-$1}"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  ok  $cmd"
    return 0
  fi
  echo "  miss $cmd"
  MISSING+=("$cmd:$brew_pkg")
  return 1
}

echo "Checking dependencies..."
need python3
need sqlite3
need jq
need rg ripgrep

if [ "${#MISSING[@]}" -eq 0 ]; then
  echo "All dependencies present."
  exit 0
fi

if [ "$INSTALL" -ne 1 ]; then
  echo
  echo "Missing: ${MISSING[*]//:*/}"
  echo "Run: $0 --install   (macOS + Homebrew)"
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install https://brew.sh or install packages manually." >&2
  exit 1
fi

for entry in "${MISSING[@]}"; do
  pkg="${entry#*:}"
  echo "brew install $pkg"
  brew install "$pkg"
done

echo "Done."
