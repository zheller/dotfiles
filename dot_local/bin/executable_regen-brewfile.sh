#!/usr/bin/env bash
set -euo pipefail

brewfile="${HOMEBREW_BUNDLE_FILE:-$HOME/Brewfile}"
tmp="$(mktemp)"

# Generate Brewfile from current machine state
brew bundle dump --describe --force --file="$tmp"

# Only replace if changed
if [ -f "$brewfile" ] && cmp -s "$tmp" "$brewfile"; then
  rm -f "$tmp"
  echo "Brewfile unchanged."
else
  mv "$tmp" "$brewfile"
  echo "Updated: $brewfile"
fi
