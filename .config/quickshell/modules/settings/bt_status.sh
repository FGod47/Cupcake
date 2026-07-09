#!/bin/bash
POWERED=$(bluetoothctl show | grep -q "Powered: yes" && echo "true" || echo "false")
if [ "$POWERED" = "false" ]; then
    echo '{"powered":false,"devices":[]}'
    exit 0
fi

echo -n '{"powered":true,"devices":['

FIRST=true
while read -r line; do
    if [[ $line =~ ^Device\ ([0-9A-F:]+)\ (.*)$ ]]; then
        MAC="${BASH_REMATCH[1]}"
        NAME="${BASH_REMATCH[2]}"
        
        INFO=$(bluetoothctl info "$MAC")
        PAIRED=$(echo "$INFO" | grep -q "Paired: yes" && echo "true" || echo "false")
        CONNECTED=$(echo "$INFO" | grep -q "Connected: yes" && echo "true" || echo "false")
        
        if [ "$FIRST" = "true" ]; then FIRST=false; else echo -n ","; fi
        echo -n "{\"mac\":\"$MAC\",\"name\":\"$NAME\",\"paired\":$PAIRED,\"connected\":$CONNECTED}"
    fi
done <<< "$(bluetoothctl devices)"

echo ']}'
