#!/bin/bash

SELECTED_INDEX="$1"

BACKGROUNDS_DIR="$HOME/.config/theme/backgrounds/"
CURRENT_BACKGROUND_LINK="$HOME/.config/background"

BACKGROUNDS=()
while IFS= read -r -d '' file; do
	BACKGROUNDS+=("$file")
done < <(find -L "$BACKGROUNDS_DIR" -type f -print0 | sort -z)
TOTAL=${#BACKGROUNDS[@]}

if [[ $TOTAL -eq 0 ]]; then
	echo "No backgrounds found in $BACKGROUNDS_DIR"
	exit 1
else
	if [[ -n "$SELECTED_INDEX" ]]; then
		# Validate the index parameter (1-based)
		if ! [[ "$SELECTED_INDEX" =~ ^[0-9]+$ ]] || [[ "$SELECTED_INDEX" -lt 1 ]] || [[ "$SELECTED_INDEX" -gt "$TOTAL" ]]; then
			echo "Invalid index. Please provide a number between 1 and $TOTAL"
			exit 1
		fi
		# Convert 1-based index to 0-based array index
		NEW_BACKGROUND="${BACKGROUNDS[$((SELECTED_INDEX - 1))]}"
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
	fi

	# Set new background symlink
	ln -nsf "$NEW_BACKGROUND" "$CURRENT_BACKGROUND_LINK"

	if [[ "$OSTYPE" == "darwin"* ]]; then
		echo "Setting wallpaper for macOS"

		# Clear wallpaper cache and refresh
		rm -rf "$HOME/Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches/com.apple.wallpaper.caches/"
		killall WallpaperAgent &>/dev/null || true
		killall Dock &>/dev/null || true

		# Finally set the new wallpaper
		osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$NEW_BACKGROUND\""
	else
		echo "Nothing to do for non-macOS systems"
	fi
fi
