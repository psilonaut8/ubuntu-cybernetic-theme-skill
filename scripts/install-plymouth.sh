#!/usr/bin/env bash
set -Eeuo pipefail
theme_name='ubuntu-cybernetic'
theme_dest="/usr/share/plymouth/themes/$theme_name"
theme_alt="$theme_dest/$theme_name.plymouth"
alt_group='default.plymouth'
script_dir=$(cd -- "$(dirname -- "$BASH_SOURCE")" && pwd)
source_dir="$script_dir/../assets/plymouth/$theme_name"
restore_source="$script_dir/restore-plymouth.sh"

[[ $EUID -eq 0 ]] || {
  echo 'Run this installer as root, for example: sudo bash scripts/install-plymouth.sh' >&2
  exit 1
}
. /etc/os-release
[[ "$ID" == ubuntu || "$ID" == debian ]] || {
  echo "This installer supports Ubuntu and Debian; found $ID." >&2
  exit 1
}
for tool in update-alternatives update-initramfs lsinitramfs; do
  command -v "$tool" >/dev/null || { echo "Required command not found: $tool" >&2; exit 1; }
done
[[ -f "$source_dir/$theme_name.plymouth" && -f "$source_dir/$theme_name.script" ]] || {
  echo "Plymouth theme assets are missing from $source_dir" >&2
  exit 1
}
[[ ! -e "$theme_dest" && ! -L "$theme_dest" ]] || {
  echo "Refusing to overwrite existing theme directory: $theme_dest" >&2
  exit 1
}
plugin_path=$(find /usr/lib /usr/lib64 -type f -path '*/plymouth/script.so' -print -quit 2>/dev/null || true)
[[ -n "$plugin_path" ]] || {
  echo 'Plymouth script plugin is not installed; no changes made.' >&2
  exit 1
}
alt_state=$(update-alternatives --query "$alt_group") || {
  echo "Plymouth alternative group $alt_group is not configured; no changes made." >&2
  exit 1
}
old_status=$(awk '/^Status:/{print $2}' <<< "$alt_state")
old_value=$(awk '/^Value:/{print $2}' <<< "$alt_state")
[[ -n "$old_status" && -n "$old_value" ]] || {
  echo 'Could not read the current Plymouth alternative; no changes made.' >&2
  exit 1
}
image_count=0
for image in /boot/initrd.img-*; do
  [[ -f "$image" ]] || continue
  image_count=$((image_count + 1))
done
((image_count > 0)) || { echo 'No initramfs images found under /boot; no changes made.' >&2; exit 1; }

stamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_dir="/var/backups/ubuntu-cybernetic-plymouth-$stamp"
[[ ! -e "$backup_dir" ]] || { echo "Backup path already exists: $backup_dir" >&2; exit 1; }
install -d -o root -g root -m 0700 "$backup_dir" "$backup_dir/initramfs"
[[ ! -e /var/lib/dpkg/alternatives/default.plymouth ]] || cp -a /var/lib/dpkg/alternatives/default.plymouth "$backup_dir/alternatives-database"
[[ ! -e /etc/alternatives/default.plymouth ]] || cp -a /etc/alternatives/default.plymouth "$backup_dir/alternatives-link"
[[ ! -f /etc/plymouth/plymouthd.conf ]] || cp -a /etc/plymouth/plymouthd.conf "$backup_dir/plymouthd.conf"
for image in /boot/initrd.img-*; do
  [[ -f "$image" ]] || continue
  cp -a -- "$image" "$backup_dir/initramfs/"
done
printf 'OLD_STATUS=%q\nOLD_VALUE=%q\nPLUGIN_PATH=%q\n' "$old_status" "$old_value" "$plugin_path" > "$backup_dir/state.env"
printf 'previous_theme=%s\nprevious_status=%s\nkernel_cmdline=%s\n' \
  "$old_value" "$old_status" "$(cat /proc/cmdline)" > "$backup_dir/audit.txt"
install -m 0700 "$restore_source" "$backup_dir/rollback.sh"

mutation_started=0
on_error() {
  status=$?
  trap - ERR
  if [[ $mutation_started -eq 1 ]]; then
    echo 'Install failed; restoring the previous alternative and initramfs images.' >&2
    if ! "$backup_dir/rollback.sh" "$backup_dir"; then
      echo "Automatic restore also failed. Run: sudo $backup_dir/rollback.sh $backup_dir" >&2
    fi
  fi
  exit "$status"
}
trap on_error ERR
mutation_started=1

install -d -o root -g root -m 0755 "$theme_dest"
install -m 0644 /dev/null "$theme_dest/.package-owned"
cp -a "$source_dir"/. "$theme_dest"/
chown -R root:root "$theme_dest"
find "$theme_dest" -type d -exec chmod 0755 {} +
find "$theme_dest" -type f -exec chmod 0644 {} +
update-alternatives --install /usr/share/plymouth/themes/default.plymouth "$alt_group" "$theme_alt" 200
update-alternatives --set "$alt_group" "$theme_alt"
update-initramfs -u -k all

active=$(update-alternatives --query "$alt_group" | awk '/^Value:/{print $2}')
[[ "$active" == "$theme_alt" ]]
plugin_rel=$(sed 's#^/##' <<< "$plugin_path")
verified=0
for image in /boot/initrd.img-*; do
  [[ -f "$image" ]] || continue
  listing=$(lsinitramfs "$image")
  grep -Fq "usr/share/plymouth/themes/$theme_name/$theme_name.script" <<< "$listing"
  grep -Fq "usr/share/plymouth/themes/$theme_name/loader-01.png" <<< "$listing"
  grep -Fq "$plugin_rel" <<< "$listing"
  verified=$((verified + 1))
done
((verified > 0))
(cd "$theme_dest" && find . -type f ! -name '.package-owned' -print0 | sort -z | xargs -0 sha256sum) > "$backup_dir/theme-manifest.sha256.tmp"
(cd /boot && sha256sum initrd.img-*) > "$backup_dir/post-install-initramfs.sha256.tmp"
find /boot -maxdepth 1 -type f -name 'initrd.img-*' -printf '%f\n' | sort > "$backup_dir/post-install-initramfs-list.txt.tmp"
mv -- "$backup_dir/theme-manifest.sha256.tmp" "$backup_dir/theme-manifest.sha256"
mv -- "$backup_dir/post-install-initramfs.sha256.tmp" "$backup_dir/post-install-initramfs.sha256"
mv -- "$backup_dir/post-install-initramfs-list.txt.tmp" "$backup_dir/post-install-initramfs-list.txt"
trap - ERR
printf 'active_theme=%s\nbackup_dir=%s\nverified_initramfs_images=%s\n' "$active" "$backup_dir" "$verified"
printf 'rollback_command=sudo %s/rollback.sh %s\n' "$backup_dir" "$backup_dir"
