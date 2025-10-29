#!/bin/bash

THEME_NAME=$1

if [ -z "$THEME_NAME" ]; then
	echo "Usage: $0 <theme-name>"
	exit 1
fi

if [ ! -d "$HOME/.themes/$THEME_NAME" ]; then
	echo "Theme '$THEME_NAME' does not exist."
	exit 1
fi

if [ -d "$HOME/.config/theme" ]; then
	rm -rf "$HOME/.config/theme"
fi

ln -s "$HOME/.themes/$THEME_NAME" "$HOME/.config/theme"
