#!/usr/bin/env bash
# Launch the first available command from a list of options
# Usage: launch_first_available.sh "cmd1" "cmd2" "cmd3"

for cmd in "$@"; do
    [[ -z "$cmd" ]] && continue
    eval "command -v ${cmd%% *}" >/dev/null 2>&1 || continue
    eval "$cmd" &
    exit
done
