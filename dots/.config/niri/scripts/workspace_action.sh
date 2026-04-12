#!/usr/bin/env bash
# Niri workspace actions
# Usage: workspace_action.sh <action> <target>
# Actions: focus, move (move current window to workspace)

get_current_workspace() {
    niri msg --json focused-workspace | jq -r ".id"
}

action="$1"
shift

if [[ -z "${action}" || "${action}" == "--help" || "${action}" == "-h" || -z "$1" ]]; then
    echo "Usage: $0 <action> <target>"
    echo "Actions: focus, move"
    echo "Target: workspace number (1-10) or relative (+N, -N)"
    exit 1
fi

target="$1"

case "${action}" in
    focus|workspace)
        if [[ "$target" =~ ^[0-9]+$ ]]; then
            # Absolute workspace number - calculate actual workspace
            # Niri uses linear workspaces, so we just use the number directly
            niri msg action focus-workspace "$target"
        elif [[ "$target" == *"+"* || "$target" == *"-"* ]]; then
            # Relative workspace navigation
            if [[ "$target" == "+"* ]]; then
                niri msg action focus-workspace-next
            elif [[ "$target" == "-"* ]]; then
                niri msg action focus-workspace-previous
            fi
        else
            niri msg action focus-workspace "$target"
        fi
        ;;
    move|moveto)
        if [[ "$target" =~ ^[0-9]+$ ]]; then
            niri msg action move-column-to-workspace "$target"
        else
            niri msg action move-column-to-workspace "$target"
        fi
        ;;
    *)
        echo "Unknown action: ${action}"
        exit 1
        ;;
esac
