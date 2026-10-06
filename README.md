# Ubuntu Cybernetic Theme

A Codex skill and reusable theme components for a dark, cyan-accented Ubuntu GNOME desktop. It packages the visual changes developed for one Ubuntu setup into modular, reversible steps that can be adapted to another machine.

## Install the skill

Clone this repository into your Codex skills directory:

~~~sh
mkdir -p ~/.codex/skills
git clone https://github.com/psilonaut8/ubuntu-cybernetic-theme-skill.git ~/.codex/skills/ubuntu-cybernetic-theme
~~~

Then ask Codex to use $ubuntu-cybernetic-theme to apply the layers you want. You can also inspect and run the included component scripts yourself.

## Included

- A concise Codex skill covering the GNOME desktop profile, app drawer, GDM login appearance, Plymouth boot splash, previews, and rollback.
- An original GNOME Shell 50 app-drawer CSS overlay in navy and cyan.
- An original Plymouth script theme with a restrained status readout, scan line, compact loader, and working password/question prompts.
- Reversible installers for the app-drawer overlay, Ubuntu/Debian Plymouth, and Ubuntu-style GDM dconf appearance settings.
- A design profile that can be applied with the user's own wallpaper, fonts, and compatible GNOME extensions.

## Install optional components

Read references/components.md and references/profile.md first. The GNOME drawer script requires the active theme directory. The GDM script requires a local PNG and system-visible font. Plymouth changes require root and rebuild every installed initramfs image; it backs up those images and creates a rollback command before modifying the active theme.

Each installer has narrow preflight checks and refuses to overwrite an existing theme or recovery file. Do not remove its generated backup until the corresponding component has been checked.

## Design and compatibility

The palette is a starting point, not a requirement. The drawer stylesheet targets GNOME Shell 50. GDM and Plymouth behavior varies across Ubuntu releases, so the skill audits the installed version before applying system-wide changes. The package contains no franchise logos, characters, or wallpaper; select a background you have permission to use.

Chrome's browser-profile theme is not changed. Chrome's GTK-native dialogs can inherit the GNOME dark preference and system fonts without changing a synced browser profile.

The installers do not reboot automatically or replace GRUB.

## License

MIT. The license applies to the original scripts, CSS overlay, Plymouth theme source, and bundled small PNG theme assets in this repository. It does not grant rights to any third-party wallpaper or artwork supplied by an installer user.
