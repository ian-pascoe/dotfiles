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

# Starship
if [ -f "$CURRENT_THEME_DIR/starship.toml" ]; then
	ln -snf "$CURRENT_THEME_DIR/starship.toml" "$HOME/.config/starship.toml"
else
	ln -snf "$HOME/.dotfiles/config/starship.toml" "$HOME/.config/starship.toml"
fi

# BTop
mkdir -p "$HOME/.config/btop/themes"
ln -snf "$CURRENT_THEME_DIR/btop.theme" "$HOME/.config/btop/themes/current.theme"

# LSD
ln -snf "$CURRENT_THEME_DIR/lsd.yaml" "$HOME/.config/lsd/colors.yaml"

# Bat
mkdir -p "$HOME/.config/bat/themes"
ln -snf "$CURRENT_THEME_DIR/bat.tmTheme" "$HOME/.config/bat/themes/current.tmTheme"
bat cache --build

# K9s
mkdir -p "$HOME/.config/k9s/skins"
ln -snf "$CURRENT_THEME_DIR/k9s.yaml" "$HOME/.config/k9s/skins/current.yaml"

# Yazi
ln -snf "$CURRENT_THEME_DIR/yazi/theme.toml" "$HOME/.config/yazi/theme.toml"
if [ -d "$CURRENT_THEME_DIR/yazi/flavors" ]; then
	for flavor in "$CURRENT_THEME_DIR/yazi/flavors/"*; do
		ln -snf "$flavor" "$HOME/.config/yazi/flavors/$(basename "$flavor")"
	done
else
	# If no flavors directory, make sure ya pkg installs the theme
	ya pkg install
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
	launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.sketchybar   # restart sketchybar
	launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.jankyborders # restart jankyborders
fi

set-bg 1
