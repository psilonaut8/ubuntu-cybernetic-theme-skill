#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run this restore command as root.' >&2; exit 1; }
[[ $# -eq 1 ]] || { echo "Usage: sudo $0 /var/backups/ubuntu-cybernetic-gdm-TIMESTAMP" >&2; exit 2; }
backup_dir=$(realpath -e -- "$1")
case "$backup_dir" in
  /var/backups/ubuntu-cybernetic-gdm-*) ;;
  *) echo 'Refusing a backup directory outside /var/backups/ubuntu-cybernetic-gdm-*.' >&2; exit 1 ;;
esac
[[ -f "$backup_dir/greeter-dconf-defaults" && -f "$backup_dir/post-install.sha256" ]] || {
  echo "Incomplete GDM backup: $backup_dir" >&2
  exit 1
}
current_hash=$(sha256sum /etc/gdm3/greeter.dconf-defaults | awk '{print $1}')
expected_hash=$(<"$backup_dir/post-install.sha256")
[[ "$current_hash" == "$expected_hash" ]] || {
  echo 'GDM defaults changed after this package was installed. Refusing to overwrite later edits.' >&2
  exit 1
}
install -m 0644 "$backup_dir/greeter-dconf-defaults" /etc/gdm3/greeter.dconf-defaults
if [[ -f "$backup_dir/compiled-greeter-dconf-defaults" ]]; then
  install -o gdm -g gdm -m 0644 "$backup_dir/compiled-greeter-dconf-defaults" /var/lib/gdm3/greeter-dconf-defaults
else
  /usr/share/gdm/generate-config
fi
if [[ -f "$backup_dir/wallpaper.path" ]]; then
  wallpaper=$(<"$backup_dir/wallpaper.path")
  wallpaper_hash=$(<"$backup_dir/wallpaper.sha256")
  case "$wallpaper" in
    /usr/local/share/backgrounds/ubuntu-cybernetic-gdm-*.png)
      if [[ -f "$wallpaper" ]] && [[ "$(sha256sum "$wallpaper" | awk '{print $1}')" == "$wallpaper_hash" ]]; then
        rm -- "$wallpaper"
      else
        echo "Keeping wallpaper because it changed since install: $wallpaper" >&2
      fi
      ;;
    *) echo "Ignoring unexpected wallpaper path in backup: $wallpaper" >&2 ;;
  esac
fi
printf 'Restored GDM defaults. Sign out or reboot manually to inspect the restored greeter.\n'
