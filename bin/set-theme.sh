#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: $0 <theme-name>"
	exit 1
fi

THEMES_DIR="$HOME/.themes"
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

mkdir -p ~/.config/btop/themes
ln -snf "$CURRENT_THEME_DIR/btop.theme" ~/.config/btop/themes/current.theme

if [[ "$OSTYPE" == "darwin"* ]]; then
	echo "Setting wallpaper for macOS"
	wallpaper set ~/.config/theme/backgrounds/background-1.png
	launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.sketchybar   # restart sketchybar
	launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.jankyborders # restart jankyborders
fi
