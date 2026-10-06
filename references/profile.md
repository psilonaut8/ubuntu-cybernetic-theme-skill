# Source profile

This repository packages a GitS-inspired dark cybernetic visual profile for reuse. Its settings are references, not fixed requirements; inspect the target system and let the user choose which layers to apply.

## Desktop and GNOME Shell

- GTK theme: Yaru-dark.
- Color scheme: prefer-dark.
- Built-in accent: teal, as a close match for the cyan drawer palette.
- Interface font: Chakra Petch SemiBold 11 where installed.
- Monospace labels: JetBrains Mono where installed; substitute an available readable monospace otherwise.
- Icons: Papirus-Dark where installed.
- App drawer: deep navy surfaces, cyan focus states, square geometry, and compact monospace labels. The included overlay is specifically for GNOME Shell 50.
- The source system used GitS-GNOME as its base Shell theme. This repository contains only the app-drawer overlay, not the upstream theme files.
- Dash to Panel may be configured as a solid charcoal top panel at 34 px. Check its installed schema and current panel layout before applying.
- Just Perfection may hide selected overview controls. Use the installed extension's current preferences rather than assuming key names.
- Vitals may show CPU load, memory use, CPU temperature, network rate, and battery percentage at a five-second interval. Discover the actual sensors and battery device on each machine.

## Login and boot

- GDM appearance: dark Yaru styling, a system-visible font, a teal accent, and a user-selected local PNG wallpaper. The installer stores a system-readable copy and preserves the original GDM defaults for rollback.
- Plymouth: near-black background, restrained cyan/teal status lines, a slow scan line, small loader, and visible password/question callbacks for unlock and recovery prompts.
- The Plymouth installer keeps the existing boot manager and kernel command line, backs up each initramfs image, and does not reboot.

## Optional terminal and browser behavior

- Kitty can use a dark cyan/violet palette, modest opacity, and a readable monospace font. The application and palette are optional; this repository does not install Kitty.
- Chrome's browser profile and synced theme were left untouched. GTK-backed dialogs can inherit the GNOME font and dark preference; Chromium's browser frame and web pages remain under Chrome's own theme and site settings.

## Wallpapers and rights

The source machine used a user-selected dark environment wallpaper. No wallpaper art is bundled here. Use an image you have permission to use; the GDM script copies only the selected PNG to a system-readable location.
