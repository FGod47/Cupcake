#!/bin/bash

# Get official repo updates
PACMAN_UPDATES=$(checkupdates 2>/dev/null)
# Get AUR updates
AUR_UPDATES=$(yay -Qu --aur 2>/dev/null)

TOTAL_COUNT=0
AUR_COUNT=0
JSON_ARRAY="["

process_updates() {
    local updates="$1"
    local is_aur="$2"
    
    while IFS= read -r line; do
        if [ -z "$line" ]; then continue; fi
        
        # Format: package oldver -> newver
        # Extract fields using awk. Yay and checkupdates both use this format.
        NAME=$(echo "$line" | awk '{print $1}')
        OLD=$(echo "$line" | awk '{print $2}')
        NEW=$(echo "$line" | awk '{print $4}')
        
        if [ "$TOTAL_COUNT" -gt 0 ]; then
            JSON_ARRAY+=","
        fi
        
        JSON_ARRAY+="{\"name\": \"$NAME\", \"old\": \"$OLD\", \"ver\": \"$NEW\", \"aur\": $is_aur}"
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        if [ "$is_aur" = "true" ]; then
            AUR_COUNT=$((AUR_COUNT + 1))
        fi
    done <<< "$updates"
}

if [ -n "$PACMAN_UPDATES" ]; then
    process_updates "$PACMAN_UPDATES" "false"
fi

if [ -n "$AUR_UPDATES" ]; then
    process_updates "$AUR_UPDATES" "true"
fi

JSON_ARRAY+="]"

# Output JSON object
cat <<EOF
{
  "total": $TOTAL_COUNT,
  "aur": $AUR_COUNT,
  "packages": $JSON_ARRAY
}
EOF
