# Hahlh fork of herdr

Private-use fork. Upstream (`herdrdev/herdr`) does not accept outside pull
requests, so local fixes live here.

- `master` tracks upstream and is never edited.
- `patches` is upstream's latest stable tag plus our commits. Keep it to a
  handful of small, self-contained commits so rebasing stays trivial.
- `scripts/fork/rebuild.sh` fetches upstream tags, rebases `patches` onto the
  newest `v*` tag, builds with Zig 0.15.2, runs the platform tests, and installs
  to `~/.local/bin/herdr`. Use it instead of `herdr update` (which would
  overwrite the patched binary with the stock release).

Current patches:

- Bounded clipboard helper waits (`src/platform/linux.rs`): `wl-copy` /
  `wl-paste` / `xclip` / `xsel` are killed after 3 s so a stuck helper on GNOME
  Wayland cannot freeze the client's input loop. Context: upstream issue #2621
  (mutter `meta_window_set_stack_position_no_sync` assertion on every
  wl-clipboard call; observed 2026-08-19 on Fedora 43, GNOME 49.9).
