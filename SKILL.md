---
name: ubuntu-cybernetic-theme
description: "Apply or customize a dark cybernetic visual profile across Ubuntu GNOME, its app drawer, GDM login screen, and Plymouth boot splash. Use when someone wants this cohesive desktop theme or wants to adapt it to their own Ubuntu system."
---

# Ubuntu Cybernetic Theme

Help the user apply a cohesive, original dark cybernetic look to Ubuntu GNOME. Work with the system's installed GNOME, GDM, and Plymouth versions; do not assume that one preset fits every release.

## Style reference

Use these values as a starting point and adapt them to the user's existing choices:

- Deep navy surfaces: #080d16 and #0d1724.
- Cyan focus accent: #35eaff; light text: #e8f8ff; muted labels: #9fc5d6.
- Prefer Yaru-dark, a dark color scheme, and the closest built-in teal accent.
- Chakra Petch for interface text and JetBrains Mono for technical labels when installed; use an installed readable fallback otherwise.
- Papirus-Dark icons where available.
- A compact, solid charcoal top panel; avoid visual effects that increase battery or graphics load without a clear benefit.

The app-drawer overlay in assets/app-drawer/gnome-shell-50.css targets GNOME Shell 50. Inspect the installed Shell version and active user theme before using it. Do not append it to an unrelated system theme without a backup.

## Workflow

1. Inspect the Ubuntu release, GNOME Shell and session type, active GTK and Shell themes, available fonts/icons, installed extensions, current wallpaper, GDM configuration method, Plymouth alternative, initramfs generator, and installed kernel images. Record which components are already present.
2. Ask which layers the user wants if their request is not specific: desktop profile, app drawer, GDM, Plymouth, or wallpaper. Treat GDM and Plymouth as separate system-wide changes; keep them optional.
3. Adapt the profile to the installed versions. Use supported GNOME settings and extension preferences. Detect Vitals sensors and battery names before choosing its readings. Do not change Chrome profile themes or synced preferences as a side effect; GTK-native dialogs can inherit system appearance.
4. For the app drawer, use the included stylesheet only on GNOME Shell 50. Back up the exact active theme stylesheet before adding the overlay, and provide a matching restore command. On other Shell versions, inspect their stylesheet and adapt the selectors.
5. For GDM, prefer Ubuntu's greeter dconf defaults when the installed GDM provides that supported path. Copy a user-selected wallpaper to a system-readable location and verify any requested font is available to the greeter. Preserve authentication, accessibility, session, input, and power controls. Do not replace or patch compiled GNOME Shell theme resources.
6. For Plymouth, keep the existing boot manager and kernel command line. Use the native script plugin and retain password and question callbacks. Before changing the active alternative or rebuilding initramfs images, save the previous alternative state and exact copies of the images being replaced. Verify the selected alternative and theme files inside every rebuilt image. Never reboot automatically.
7. Report what changed, what was verified, where backups are stored, and the exact restore command for each installed layer. Distinguish static preview or syntax checks from live greeter or boot verification.

The included scripts support the GNOME 50 drawer overlay, Ubuntu/Debian Plymouth installation, and Ubuntu-style GDM dconf defaults. Read references/components.md before using a script; stop and adapt when its preflight checks do not match the target system.
