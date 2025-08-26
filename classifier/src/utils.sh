#!/bin/bash
# check if LOGFILE is set

if [ -z "$LOGFILE" ]; then
    NOW=$(date +"%Y-%m-%d_%H-%M-%S")
    mkdir -p "$OUTPUT_BASE_DIR/logs"
    LOGFILE="$OUTPUT_BASE_DIR/logs/log_${NOW}.txt"
fi

log() {
    echo "[$(date -Is)]" "$@" | tee -a $LOGFILE
}