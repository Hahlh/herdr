#!/usr/bin/env bash
# Rebuild this fork's patched herdr on top of an upstream stable tag and install it.
#
# Usage:
#   scripts/fork/rebuild.sh            # rebase onto newest upstream v* tag, build, install
#   scripts/fork/rebuild.sh v0.8.1     # same, but onto a specific tag
#   scripts/fork/rebuild.sh --no-rebase  # just build and install the current branch
#
# Requires: cargo, Zig 0.15.2 (ZIG env var or ~/.local/share/zig/0.15.2/zig),
# remotes "origin" (fork) and "upstream" (herdrdev/herdr).
#
# The installed binary goes to ~/.local/bin/herdr via an atomic rename, the same
# way `herdr update` installs. Running herdr processes keep the old inode; detach
# and re-attach the client (and restart the server when a release changes the
# protocol) to pick up the new build.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo"

export ZIG="${ZIG:-$HOME/.local/share/zig/0.15.2/zig}"
if ! "$ZIG" version >/dev/null 2>&1; then
  echo "zig not found at $ZIG (need 0.15.2; set ZIG=...)" >&2
  exit 1
fi

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" != "patches" ]]; then
  echo "expected to be on branch 'patches', on '$branch'" >&2
  exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  echo "working tree not clean; commit or stash first" >&2
  exit 1
fi

rebase=1
target=""
for arg in "$@"; do
  case "$arg" in
    --no-rebase) rebase=0 ;;
    v*) target="$arg" ;;
    *) echo "unknown argument: $arg" >&2; exit 1 ;;
  esac
done

if (( rebase )); then
  git fetch upstream --tags --quiet
  base=$(git describe --tags --abbrev=0 --match 'v*' HEAD)
  if [[ -z "$target" ]]; then
    target=$(git tag --list 'v*' --sort=-v:refname | head -1)
  fi
  if [[ "$base" == "$target" ]]; then
    echo "already based on $target"
  else
    echo "rebasing patches from $base onto $target"
    git rebase --onto "$target" "$base"
  fi
fi

echo "building $(git describe --tags --always)"
cargo build --release
cargo test --bin herdr platform::linux::tests --quiet

dest="$HOME/.local/bin/herdr"
tmp="$dest.new"
cp target/release/herdr "$tmp"
chmod 755 "$tmp"
mv -f "$tmp" "$dest"
echo "installed $("$dest" --version) to $dest"
echo "next: detach the herdr client and run 'herdr' again to pick up the new binary"
