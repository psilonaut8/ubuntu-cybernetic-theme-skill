#!/usr/bin/env bash
set -Eeuo pipefail
wallpaper=''
font='Ubuntu Sans 11'
while (($#)); do
  case "$1" in
    --wallpaper) (($# >= 2)) || exit 2; wallpaper=$2; shift 2 ;;
    --font) (($# >= 2)) || exit 2; font=$2; shift 2 ;;
    *) echo "Usage: sudo $0 --wallpaper /path/to/image.png [--font 'Font Family 11']" >&2; exit 2 ;;
  esac
done
[[ $EUID -eq 0 ]] || { echo 'Run this installer as root.' >&2; exit 1; }
[[ -n "$wallpaper" ]] || { echo 'A local PNG is required: --wallpaper /path/to/image.png' >&2; exit 2; }
wallpaper=$(realpath -e -- "$wallpaper")
[[ -r "$wallpaper" && "$(file --brief --mime-type "$wallpaper")" == image/png ]] || {
  echo 'The selected wallpaper must be a readable PNG.' >&2
  exit 1
}
[[ "$font" =~ ^[A-Za-z0-9\ ._-]+$ ]] || {
  echo 'Font name may contain only letters, numbers, spaces, period, underscore, and hyphen.' >&2
  exit 2
}
for path in /etc/gdm3/greeter.dconf-defaults /usr/share/gdm/generate-config /usr/share/dconf/profile/gdm; do
  [[ -e "$path" ]] || { echo "Expected Ubuntu-style GDM configuration path is missing: $path" >&2; exit 1; }
done
for tool in python3 fc-match dconf sha256sum gsettings file; do
  command -v "$tool" >/dev/null || { echo "Required command not found: $tool" >&2; exit 1; }
done
font_match=$(fc-match -f '%{family}' "$font" | head -n1)
[[ -n "$font_match" ]] || { echo "Font is not available to fontconfig: $font" >&2; exit 1; }
for schema_key in \
  'com.ubuntu.login-screen background-picture-uri' \
  'com.ubuntu.login-screen background-size' \
  'com.ubuntu.login-screen background-repeat' \
  'com.ubuntu.login-screen background-color'; do
  read -r schema key <<< "$schema_key"
  gsettings range "$schema" "$key" >/dev/null 2>&1 || {
    echo "This GDM release does not expose the expected key $schema/$key; no changes made." >&2
    exit 1
  }
done
config='/etc/gdm3/greeter.dconf-defaults'
if grep -Fq 'Ubuntu Cybernetic appearance overrides' "$config"; then
  echo 'Ubuntu Cybernetic GDM overrides are already present; no changes made.' >&2
  exit 1
fi

stamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_dir="/var/backups/ubuntu-cybernetic-gdm-$stamp"
wallpaper_dest="/usr/local/share/backgrounds/ubuntu-cybernetic-gdm-$stamp.png"
[[ ! -e "$backup_dir" && ! -e "$wallpaper_dest" ]] || {
  echo 'A backup or wallpaper destination already exists; refusing to overwrite it.' >&2
  exit 1
}
install -d -o root -g root -m 0700 "$backup_dir"
cp -a "$config" "$backup_dir/greeter-dconf-defaults"
if [[ -f /var/lib/gdm3/greeter-dconf-defaults ]]; then
  cp -a /var/lib/gdm3/greeter-dconf-defaults "$backup_dir/compiled-greeter-dconf-defaults"
fi
install -m 0700 "$(dirname -- "$(realpath -- "$0")")/restore-gdm.sh" "$backup_dir/rollback.sh"
cp -- "$wallpaper" "$wallpaper_dest"
chmod 0644 "$wallpaper_dest"
printf '%s\n' "$wallpaper_dest" > "$backup_dir/wallpaper.path"
sha256sum "$wallpaper_dest" | awk '{print $1}' > "$backup_dir/wallpaper.sha256"

on_error() {
  status=$?
  trap - ERR
  if [[ -f "$backup_dir/greeter-dconf-defaults" ]]; then
    install -m 0644 "$backup_dir/greeter-dconf-defaults" "$config" || true
  fi
  if [[ -f "$backup_dir/compiled-greeter-dconf-defaults" ]]; then
    install -o gdm -g gdm -m 0644 "$backup_dir/compiled-greeter-dconf-defaults" /var/lib/gdm3/greeter-dconf-defaults || true
  else
    /usr/share/gdm/generate-config || true
  fi
  [[ ! -f "$wallpaper_dest" ]] || rm -f -- "$wallpaper_dest"
  exit "$status"
}
trap on_error ERR

python3 - "$config" "$wallpaper_dest" "$font" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
wallpaper = Path(sys.argv[2])
font = sys.argv[3]
text = path.read_text()
marker = "# Ubuntu Cybernetic appearance overrides"
if marker in text:
    raise SystemExit("Managed overrides already exist")

def add_keys(source, section, values):
    header = f"[{section}]"
    lines = source.splitlines(keepends=True)
    indexes = [i for i, line in enumerate(lines) if line.strip() == header]
    if len(indexes) > 1:
        raise SystemExit(f"Found duplicate dconf groups for {section}; refusing an ambiguous edit")
    keys = [key for key, _ in values]
    if indexes:
        start = indexes[0]
        end = next((i for i in range(start + 1, len(lines)) if re.match(r"^\s*\[.+\]\s*$", lines[i])), len(lines))
        existing = set()
        for line in lines[start + 1:end]:
            match = re.match(r"^\s*([A-Za-z0-9_-]+)\s*=", line)
            if match:
                existing.add(match.group(1))
        conflicts = existing.intersection(keys)
        if conflicts:
            raise SystemExit(f"Existing settings in {section} would be overwritten: {', '.join(sorted(conflicts))}")
        addition = [f"{key}={value}\n" for key, value in values]
        if end > start + 1 and not lines[end - 1].endswith("\n"):
            lines[end - 1] += "\n"
        lines[end:end] = addition
        return "".join(lines)
    suffix = "" if not source or source.endswith("\n") else "\n"
    return source + suffix + "\n" + header + "\n" + "".join(f"{key}={value}\n" for key, value in values)

text = add_keys(text, "org/gnome/desktop/interface", [
    ("font-name", "'" + font + "'"),
    ("gtk-theme", "'Yaru-dark'"),
    ("color-scheme", "'prefer-dark'"),
    ("accent-color", "'teal'"),
])
text = add_keys(text, "com/ubuntu/login-screen", [
    ("background-picture-uri", "'file://" + str(wallpaper) + "'"),
    ("background-color", "'#020908'"),
    ("background-repeat", "'no-repeat'"),
    ("background-size", "'contain'"),
])
text = text.rstrip() + "\n\n" + marker + "\n"
path.write_text(text)
PY
/usr/share/gdm/generate-config
profile=$(mktemp)
query_config=$(mktemp -d)
printf 'file-db:/var/lib/gdm3/greeter-dconf-defaults\n' > "$profile"
verify_setting() {
  local key=$1 expected=$2 actual
  actual=$(XDG_CONFIG_HOME="$query_config" DCONF_PROFILE="$profile" dconf read "$key")
  [[ "$actual" == "$expected" ]] || {
    echo "GDM verification failed for $key: expected $expected, got $actual" >&2
    return 1
  }
}
verify_setting /com/ubuntu/login-screen/background-picture-uri "'file://$wallpaper_dest'"
verify_setting /com/ubuntu/login-screen/background-size "'contain'"
verify_setting /com/ubuntu/login-screen/background-repeat "'no-repeat'"
verify_setting /com/ubuntu/login-screen/background-color "'#020908'"
verify_setting /org/gnome/desktop/interface/font-name "'$font'"
verify_setting /org/gnome/desktop/interface/gtk-theme "'Yaru-dark'"
verify_setting /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
verify_setting /org/gnome/desktop/interface/accent-color "'teal'"
rm -rf -- "$query_config" "$profile"
sha256sum "$config" | awk '{print $1}' > "$backup_dir/post-install.sha256"
trap - ERR
printf 'GDM defaults installed and database verified.\n'
printf 'Backup: %s\n' "$backup_dir"
printf 'No GDM reload was performed. Sign out or reboot manually to inspect the greeter.\n'
printf 'Restore with: sudo %s/rollback.sh %s\n' "$backup_dir" "$backup_dir"
