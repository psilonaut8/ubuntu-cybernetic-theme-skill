#!/usr/bin/env bash
set -Eeuo pipefail
usage() { echo "Usage: $0 /path/to/active-user-theme" >&2; exit 2; }
[[ $# -eq 1 ]] || usage
theme_dir=$(realpath -e -- "$1") || usage
stylesheet="$theme_dir/gnome-shell/gnome-shell.css"
script_dir=$(cd -- "$(dirname -- "$BASH_SOURCE")" && pwd)
overlay="$script_dir/../assets/app-drawer/gnome-shell-50.css"
marker='Ubuntu Cybernetic app drawer — GNOME Shell 50'
[[ -f "$stylesheet" ]] || { echo "Missing Shell stylesheet: $stylesheet" >&2; exit 1; }
[[ -r "$overlay" ]] || { echo "Missing overlay: $overlay" >&2; exit 1; }
version=$(gnome-shell --version 2>/dev/null || true)
if [[ "$version" != *" 50."* ]]; then
  echo "This overlay targets GNOME Shell 50; found: $version. Adapt its selectors before installing." >&2
  exit 1
fi
if grep -Fq "$marker" "$stylesheet"; then
  echo 'The app-drawer overlay is already present; no change made.'
  exit 0
fi
stamp=$(date -u +%Y%m%dT%H%M%SZ)
backup="$stylesheet.before-ubuntu-cybernetic-$stamp"
installed_hash="$backup.installed-sha256"
[[ ! -e "$backup" && ! -e "$installed_hash" ]] || {
  echo "Recovery path already exists: $backup" >&2
  exit 1
}
cp -p -- "$stylesheet" "$backup"
if ! cat -- "$overlay" >> "$stylesheet"; then
  cp -p -- "$backup" "$stylesheet"
  exit 1
fi
if ! cmp -s <(tail -c "$(wc -c < "$overlay")" "$stylesheet") "$overlay"; then
  cp -p -- "$backup" "$stylesheet"
  echo 'Overlay verification failed; original stylesheet restored.' >&2
  exit 1
fi
sha256sum "$stylesheet" | awk '{print $1}' > "$installed_hash"
chmod 0600 "$installed_hash"
printf 'Updated: %s\nBackup: %s\n' "$stylesheet" "$backup"
printf 'After logging out and back in, restore with:\n  bash %q --target %q --backup %q\n' \
  "$script_dir/restore-app-drawer.sh" "$stylesheet" "$backup"
