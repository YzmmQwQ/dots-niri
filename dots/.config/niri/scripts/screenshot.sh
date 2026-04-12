#!/usr/bin/env bash
# Screenshot script for Niri
# Uses grim + slurp for region selection

SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Screenshots"
mkdir -p "$SCREENSHOTS_DIR"

FILENAME="Screenshot_$(date '+%Y-%m-%d_%H.%M.%S').png"

case "$1" in
    region)
        # Screenshot selected region
        grim -g "$(slurp)" - | wl-copy
        echo "Region screenshot copied to clipboard"
        ;;
    region-save)
        # Screenshot region and save to file
        grim -g "$(slurp)" "$SCREENSHOTS_DIR/$FILENAME"
        wl-copy < "$SCREENSHOTS_DIR/$FILENAME"
        echo "Region screenshot saved to $SCREENSHOTS_DIR/$FILENAME"
        ;;
    output|screen)
        # Screenshot focused output
        output_name=$(niri msg --json outputs | jq -r '.[] | select(.is_focused) | .name')
        grim -o "$output_name" - | wl-copy
        echo "Screen screenshot copied to clipboard"
        ;;
    output-save|screen-save)
        # Screenshot focused output and save
        output_name=$(niri msg --json outputs | jq -r '.[] | select(.is_focused) | .name')
        grim -o "$output_name" "$SCREENSHOTS_DIR/$FILENAME"
        wl-copy < "$SCREENSHOTS_DIR/$FILENAME"
        echo "Screen screenshot saved to $SCREENSHOTS_DIR/$FILENAME"
        ;;
    window)
        # Screenshot focused window
        focused_window=$(niri msg --json focused-window)
        window_id=$(echo "$focused_window" | jq -r '.id')

        # Niri doesn't have direct window screenshot, use region
        # Get window geometry from the focused window info
        grim -g "$(slurp -o)" - | wl-copy
        echo "Window screenshot copied to clipboard"
        ;;
    all|multi)
        # Screenshot all outputs
        grim - | wl-copy
        echo "All screens screenshot copied to clipboard"
        ;;
    *)
        echo "Usage: $0 {region|region-save|output|output-save|window|all}"
        echo ""
        echo "Commands:"
        echo "  region       - Select region to screenshot, copy to clipboard"
        echo "  region-save  - Select region, save to file and copy"
        echo "  output       - Screenshot focused output, copy to clipboard"
        echo "  output-save  - Screenshot focused output, save and copy"
        echo "  window       - Screenshot focused window"
        echo "  all          - Screenshot all outputs"
        exit 1
        ;;
esac
