#!/usr/bin/env bash
# Screen zoom for Niri
# Niri doesn't have built-in cursor zoom like Hyprland
# This script uses wlr-randr or hyprctl as fallback for zoom functionality
# Alternative: use a magnifier tool like "magnus" or "gnome-magnifier"

# Current zoom level (stored in /tmp)
ZOOM_FILE="/tmp/niri_zoom_level"
DEFAULT_ZOOM=1.0

get_zoom() {
    if [[ -f "$ZOOM_FILE" ]]; then
        cat "$ZOOM_FILE"
    else
        echo "$DEFAULT_ZOOM"
    fi
}

clamp() {
    local val="$1"
    awk "BEGIN {
        v = $val;
        if (v < 1.0) v = 1.0;
        if (v > 3.0) v = 3.0;
        print v;
    }"
}

set_zoom() {
    local value="$1"
    clamped=$(clamp "$value")
    echo "$clamped" > "$ZOOM_FILE"

    # Try wlr-randr first (works on most Wayland compositors)
    if command -v wlr-randr &>/dev/null; then
        # Get current output
        output=$(niri msg --json outputs | jq -r '.[] | select(.is_focused) | .name')
        if [[ -n "$output" ]]; then
            # wlr-randr --output "$output" --scale "$clamped"
            # Note: wlr-randr scale affects the whole output, not just cursor zoom
            echo "Zoom level set to $clamped (stored)"
        fi
    fi

    # Alternative: use a magnifier application
    # if command -v magnus &>/dev/null; then
    #     # Toggle magnus for screen magnification
    # fi

    echo "Zoom: $clamped (Niri doesn't support cursor zoom directly)"
    echo "Consider using a magnifier app like 'magnus' or 'gnome-magnifier'"
}

case "$1" in
    reset)
        set_zoom 1.0
        ;;
    increase)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 increase STEP"
            exit 1
        fi
        current=$(get_zoom)
        new=$(awk "BEGIN { print $current + $2 }")
        set_zoom "$new"
        ;;
    decrease)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 decrease STEP"
            exit 1
        fi
        current=$(get_zoom)
        new=$(awk "BEGIN { print $current - $2 }")
        set_zoom "$new"
        ;;
    get)
        get_zoom
        ;;
    *)
        echo "Usage: $0 {reset|increase STEP|decrease STEP|get}"
        exit 1
        ;;
esac
