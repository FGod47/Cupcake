#!/usr/bin/env bash
# Clipboard Notification Watcher
# Singleton instance with deduplication & debouncing

HASHFILE="/tmp/quickshell_clip_last.hash"

# Initialize last hash with current clipboard content
wl-paste --type text 2>/dev/null | md5sum | cut -d' ' -f1 > "$HASHFILE" 2>/dev/null

exec wl-paste --type text --watch bash -c '
    CUR=$(wl-paste --type text 2>/dev/null)
    TRIMMED=$(echo "$CUR" | xargs)
    if [ -z "$TRIMMED" ]; then
        exit 0
    fi

    CUR_HASH=$(echo "$CUR" | md5sum | cut -d" " -f1)
    LAST_HASH=""
    if [ -f "/tmp/quickshell_clip_last.hash" ]; then
        LAST_HASH=$(cat "/tmp/quickshell_clip_last.hash" 2>/dev/null)
    fi

    # Deduplicate identical clipboard changes
    if [ "$CUR_HASH" != "$LAST_HASH" ]; then
        echo "$CUR_HASH" > "/tmp/quickshell_clip_last.hash"
        PREVIEW=$(echo "$CUR" | head -n 3 | cut -c 1-180)
        notify-send "Copied to clipboard" "$PREVIEW" -a "CLIPBOARD"
    fi
'
