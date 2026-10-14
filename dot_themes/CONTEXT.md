# Theming

The color themes shared by every themed app on every machine, and how one is
chosen and switched.

## Language

**Theme variant**:
A complete theme folder under `~/.themes`, with one file per themed app; the
current theme link points at exactly one.
_Avoid_: Theme (when the folder is meant), flavor, scheme

**Theme family**:
The theme variants that are one design in light and dark, such as Catppuccin's
Mocha and Latte; at most one variant per mode. A variant not grouped with
others is a family of its own.
_Avoid_: Theme set, theme group, base theme

**Mode**:
Light or dark: the per-machine choice of which variant of a family to use, and
the system appearance that goes with it.
_Avoid_: Appearance (for the choice), background, style

**Dark-only family / light-only family**:
A family with a single variant; choosing it in the other mode uses that variant
and leaves the mode unchanged.
