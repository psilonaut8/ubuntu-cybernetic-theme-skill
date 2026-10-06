#!/usr/bin/env bash
set -Eeuo pipefail
target=''
backup=''
while (($#)); do
  case "$1" in
    --target) (($# >= 2)) || exit 2; target=$2; shift 2 ;;
    --backup) (($# >= 2)) || exit 2; backup=$2; shift 2 ;;
    *) echo "Usage: $0 --target stylesheet --backup recovery-copy" >&2; exit 2 ;;
  esac
done
[[ -n "$target" && -n "$backup" ]] || {
  echo "Usage: $0 --target stylesheet --backup recovery-copy" >&2
  exit 2
}
installed_hash="$backup.installed-sha256"
[[ -f "$target" && -f "$backup" && -f "$installed_hash" ]] || {
  echo 'Target, backup, or install-time checksum is missing.' >&2
  exit 1
}
expected=$(<"$installed_hash")
actual=$(sha256sum "$target" | awk '{print $1}')
[[ "$actual" == "$expected" ]] || {
  echo "Stylesheet changed after installation. Refusing to overwrite later edits: $target" >&2
  exit 1
}
cp -p -- "$backup" "$target"
rm -f -- "$installed_hash"
printf 'Restored %s from %s\n' "$target" "$backup"
