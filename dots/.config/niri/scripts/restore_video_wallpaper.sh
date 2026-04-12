#!/usr/bin/env bash
# Restore video wallpaper if previously set
# This script is a placeholder - video wallpaper functionality
# may need additional tools like mpvpaper or swww

WALLPAPER_STATE="$HOME/.local/state/quickshell/video_wallpaper_state"

if [[ -f "$WALLPAPER_STATE" ]]; then
    video_path=$(cat "$WALLPAPER_STATE")
    if [[ -n "$video_path" && -f "$video_path" ]]; then
        echo "Restoring video wallpaper: $video_path"
        # Use mpvpaper or similar tool
        # mpvpaper '*' "$video_path" &
        echo "Video wallpaper restoration not implemented for Niri yet"
    fi
fi
