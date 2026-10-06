#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run this restore command as root.' >&2; exit 1; }
[[ $# -eq 1 ]] || { echo "Usage: sudo $0 /var/backups/ubuntu-cybernetic-plymouth-TIMESTAMP" >&2; exit 2; }
backup_dir=$(realpath -e -- "$1")
case "$backup_dir" in
  /var/backups/ubuntu-cybernetic-plymouth-*) ;;
  *) echo 'Refusing a backup directory outside /var/backups/ubuntu-cybernetic-plymouth-*.' >&2; exit 1 ;;
esac
[[ -f "$backup_dir/state.env" && -d "$backup_dir/initramfs" ]] || {
  echo "Incomplete Plymouth backup: $backup_dir" >&2
  exit 1
}
source "$backup_dir/state.env"
theme_dest='/usr/share/plymouth/themes/ubuntu-cybernetic'
theme_alt="$theme_dest/ubuntu-cybernetic.plymouth"
alt_group='default.plymouth'
current_alt=$(update-alternatives --query "$alt_group" | awk '/^Value:/{print $2}')
if [[ "$current_alt" != "$theme_alt" && "$current_alt" != "$OLD_VALUE" ]]; then
  echo "Plymouth now selects a different theme ($current_alt). Refusing to overwrite that choice." >&2
  exit 1
fi
if [[ -f "$backup_dir/post-install-initramfs-list.txt" ]]; then
  current_list=$(mktemp)
  find /boot -maxdepth 1 -type f -name 'initrd.img-*' -printf '%f\n' | sort > "$current_list"
  if ! cmp -s "$current_list" "$backup_dir/post-install-initramfs-list.txt"; then
    rm -f -- "$current_list"
    echo 'Installed kernel initramfs set changed since theme installation. Refusing to restore stale images.' >&2
    exit 1
  fi
  rm -f -- "$current_list"
  if ! (cd /boot && sha256sum -c "$backup_dir/post-install-initramfs.sha256" >/dev/null); then
    echo 'An initramfs changed since theme installation. Refusing to overwrite it.' >&2
    exit 1
  fi
fi
if [[ -d "$theme_dest" && -f "$backup_dir/theme-manifest.sha256" ]]; then
  if ! (cd "$theme_dest" && sha256sum -c "$backup_dir/theme-manifest.sha256" >/dev/null); then
    echo 'The installed theme files changed since installation. Refusing to remove them.' >&2
    exit 1
  fi
elif [[ -d "$theme_dest" && ! -f "$theme_dest/.package-owned" ]]; then
  echo 'The theme directory is not marked as created by this installer. Refusing to remove it.' >&2
  exit 1
fi
if update-alternatives --query "$alt_group" 2>/dev/null | grep -Fqx "Alternative: $theme_alt"; then
  update-alternatives --remove "$alt_group" "$theme_alt"
fi
if [[ "$OLD_STATUS" == auto ]]; then
  update-alternatives --auto "$alt_group"
elif [[ "$OLD_VALUE" != none ]]; then
  update-alternatives --set "$alt_group" "$OLD_VALUE"
fi
for snapshot in "$backup_dir"/initramfs/initrd.img-*; do
  [[ -f "$snapshot" ]] || continue
  cp -a -- "$snapshot" "/boot/$(basename "$snapshot")"
done
if [[ -d "$theme_dest" ]]; then rm -r -- "$theme_dest"; fi
sync
active=$(update-alternatives --query "$alt_group" | awk '/^Value:/{print $2}')
if [[ "$OLD_VALUE" != none && "$active" != "$OLD_VALUE" ]]; then
  echo "Plymouth alternative verification failed: expected $OLD_VALUE, found $active" >&2
  exit 1
fi
printf 'Restored Plymouth alternative to %s\n' "$active"
printf 'Restored initramfs images from %s/initramfs\n' "$backup_dir"
