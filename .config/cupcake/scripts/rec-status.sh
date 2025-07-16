#!/bin/bash

if pgrep -x wf-recorder > /dev/null; then
    echo '{"text": "●", "tooltip": "Recording...", "class": "recording"}'
else
    echo '{"text": "", "tooltip": "Not recording"}'
fi
