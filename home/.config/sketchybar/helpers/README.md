# sketchybar helpers

This directory is intentionally almost empty.

`open_centered` — a compiled arm64 Mach-O binary — is **not** tracked in this
repo. It has no source checked in, and committing an opaque prebuilt binary to
a dotfiles repo is not worth the convenience.

It is used only by `click_script` on four right-hand bar items (clock, battery,
wifi, stats), which open a centered app window. Without it those four items
still render correctly and simply do nothing when clicked.

To restore it on a new machine, copy it from a machine that has it:

    scp old-mac:~/.config/sketchybar/helpers/open_centered \
        ~/.config/sketchybar/helpers/
    chmod +x ~/.config/sketchybar/helpers/open_centered
