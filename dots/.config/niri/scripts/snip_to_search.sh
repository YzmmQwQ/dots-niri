#!/usr/bin/env bash
# Screen snip to Google Lens search
# Takes a screenshot of a region and opens it in Google Lens

TEMP_FILE="/tmp/snip_to_search_$$.png"

# Capture region
grim -g "$(slurp)" "$TEMP_FILE"

if [[ ! -f "$TEMP_FILE" ]]; then
    echo "Failed to capture region"
    exit 1
fi

# Upload to a temporary image host or use Google Lens directly
# Google Lens URL (requires image URL or base64)
# For now, we'll open Google Images with the screenshot and let user drag-drop

# Option 1: Open Google Lens in browser (user can drag-drop the image)
xdg-open "https://lens.google.com/upload" &

# Option 2: Use a CLI tool like google-lens-cli if available
# if command -v google-lens-cli &>/dev/null; then
#     result=$(google-lens-cli "$TEMP_FILE")
#     xdg-open "$result"
# fi

# Copy to clipboard for easy pasting
wl-copy < "$TEMP_FILE"

echo "Screenshot copied to clipboard. Google Lens opened - paste the image."

# Cleanup after a delay
(sleep 30 && rm -f "$TEMP_FILE") &
