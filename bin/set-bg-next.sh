#!/bin/bash

# Cycles through the background images available

BACKGROUNDS_DIR="$HOME/.config/theme/backgrounds/"
CURRENT_BACKGROUND_LINK="$HOME/.config/background"

mapfile -d '' -t BACKGROUNDS < <(find -L "$BACKGROUNDS_DIR" -type f -print0 | sort -z)
TOTAL=${#BACKGROUNDS[@]}

if [[ $TOTAL -eq 0 ]]; then
	echo "No backgrounds found in $BACKGROUNDS_DIR"
	exit 1
else
	# Get current background from symlink
	if [[ -L "$CURRENT_BACKGROUND_LINK" ]]; then
		CURRENT_BACKGROUND=$(readlink "$CURRENT_BACKGROUND_LINK")
	else
		# Default to first background if no symlink exists
		CURRENT_BACKGROUND=""
	fi

	# Find current background index
	INDEX=-1
	for i in "${!BACKGROUNDS[@]}"; do
		if [[ "${BACKGROUNDS[$i]}" == "$CURRENT_BACKGROUND" ]]; then
			INDEX=$i
			break
		fi
	done

	# Get next background (wrap around)
	if [[ $INDEX -eq -1 ]]; then
		# Use the first background when no match was found
		NEW_BACKGROUND="${BACKGROUNDS[0]}"
	else
		NEXT_INDEX=$(((INDEX + 1) % TOTAL))
		NEW_BACKGROUND="${BACKGROUNDS[$NEXT_INDEX]}"
	fi

	# Set new background symlink
	ln -nsf "$NEW_BACKGROUND" "$CURRENT_BACKGROUND_LINK"

	if [[ "$OSTYPE" == "darwin"* ]]; then
		echo "Setting wallpaper for macOS"
		wallpaper set "$CURRENT_BACKGROUND_LINK"
	else
		echo "Nothing to do for non-macOS systems"
	fi
fi
