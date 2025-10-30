#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: $0 <theme-name>"
	exit 1
fi

THEMES_DIR="$HOME/.themes/"
CURRENT_THEME_DIR="$HOME/.config/theme"

THEME_NAME=$(echo "$1" | sed -E 's/<[^>]+>//g' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
THEME_PATH="$THEMES_DIR/$THEME_NAME"

# Check if the theme entered exists
if [[ ! -d "$THEME_PATH" ]]; then
	echo "Theme '$THEME_NAME' does not exist in $THEMES_DIR"
	exit 1
fi

echo "Linking new theme: $THEME_NAME"
ln -snf "$THEME_PATH" "$CURRENT_THEME_DIR"

# Reload btop theme
mkdir -p ~/.config/btop/themes
ln -snf "$CURRENT_THEME_DIR/btop.theme" ~/.config/btop/themes/current.theme

# Reload lsd
ln -snf "$CURRENT_THEME_DIR/lsd.yaml" ~/.config/lsd/colors.yaml

# Reload bat theme
mkdir -p ~/.config/bat/themes
ln -snf "$CURRENT_THEME_DIR/bat.tmTheme" ~/.config/bat/themes/current.tmTheme
bat cache --build

mkdir -p ~/.config/k9s/skins
ln -snf "$CURRENT_THEME_DIR/k9s.yaml" ~/.config/k9s/skins/current.yaml

if [[ "$OSTYPE" == "darwin"* ]]; then
	echo "Setting wallpaper for macOS"
	launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.sketchybar   # restart sketchybar
	launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.jankyborders # restart jankyborders
fi

set-bg-next
