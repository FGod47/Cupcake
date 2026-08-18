#!/usr/bin/env bash
# Clipboard Notification Watcher
# Singleton instance with deduplication & debouncing

PIDFILE="/tmp/quickshell_clip_notify.pid"
HASHFILE="/tmp/quickshell_clip_last.hash"

# Ensure singleton execution
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null && [ "$OLD_PID" != "$$" ]; then
        kill "$OLD_PID" 2>/dev/null
    fi
fi
echo "$$" > "$PIDFILE"

# Clean exit handler
cleanup() {
    rm -f "$PIDFILE" 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# Initialize last hash with current clipboard content
wl-paste --type text 2>/dev/null | md5sum | cut -d' ' -f1 > "$HASHFILE" 2>/dev/null

wl-paste --type text --watch bash -c '
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
