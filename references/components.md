# Components and commands

Read this before running one of the bundled installers. The scripts deliberately stop if their expected component is missing or a destination would overwrite existing data.

## GNOME app drawer

The stylesheet in assets/app-drawer/gnome-shell-50.css is a focused overlay for GNOME Shell 50. The install script takes the active user theme directory:

~~~sh
bash scripts/install-app-drawer.sh "$HOME/.themes/ACTIVE-THEME"
~~~

It backs up gnome-shell/gnome-shell.css next to the original, then appends the overlay once. Log out and back in on Wayland to reload the theme. Restore with:

~~~sh
bash scripts/restore-app-drawer.sh --target "$HOME/.themes/ACTIVE-THEME/gnome-shell/gnome-shell.css" --backup "/path/printed-by-installer"
~~~

## Plymouth boot splash

Run on Ubuntu or Debian from a root-capable terminal:

~~~sh
sudo bash scripts/install-plymouth.sh
~~~

The installer refuses to replace an existing ubuntu-cybernetic theme, backs up the previous Plymouth alternative and every existing /boot/initrd.img-* image under /var/backups, installs the theme, rebuilds all installed images, and checks the theme script, loader image, and script plugin in every image. It does not edit GRUB or reboot.

The installer prints a root-run rollback command. Keep the backup directory until the new boot splash has been confirmed after a manual reboot.

## GDM login appearance

Ubuntu-style GDM defaults require a local PNG wallpaper and an installed system font. Example:

~~~sh
sudo bash scripts/install-gdm.sh --wallpaper "$HOME/Pictures/wallpaper.png" --font "Chakra Petch SemiBold 11"
~~~

The installer copies the wallpaper to /usr/local/share/backgrounds, backs up the GDM defaults and compiled database, writes only the selected appearance keys, and regenerates the database. It does not reload or restart GDM, because that could end the current session. Sign out or reboot manually to inspect the greeter.

The installer prints its restore command. Restore before removing its backup directory.

## Desktop appearance and optional extensions

Use the skill to inspect and set GNOME interface font, monospace font, dark color scheme, GTK theme, icon theme, accent, wallpaper, and extension settings. Save the prior values of each changed key so they can be restored independently. Prefer GNOME Settings or Extension Manager for extension installation, and do not install extensions whose release is not compatible with the installed Shell version.

Useful profile choices from the source system include Yaru-dark, Papirus-Dark, Chakra Petch, JetBrains Mono, Dash to Panel, Just Perfection, and Vitals. Panel placement, battery slot, sensors, fonts, extension versions, and wallpaper paths vary by machine; discover them instead of copying device-specific values.
