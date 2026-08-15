#!/usr/bin/env bash
# Clipboard Notification Watcher
# Triggers luxury notification card on copy

# Ignore the first initial read on startup
INITIAL_VAL=$(wl-paste --type text 2>/dev/null)
PREV="$INITIAL_VAL"

wl-paste --type text --watch bash -c '
    CUR=$(wl-paste --type text 2>/dev/null)
    # Ignore empty or whitespace-only
    TRIMMED=$(echo "$CUR" | xargs)
    if [ -n "$TRIMMED" ]; then
        # Format body preview: max 3 lines, up to 180 chars
        PREVIEW=$(echo "$CUR" | head -n 3 | cut -c 1-180)
        notify-send "Copied to clipboard" "$PREVIEW" -a "PIBBLE"
    fi
'
