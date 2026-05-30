#!/bin/bash

# Simple script to recursively scan a folder for files larger than 10MB.
# It prints paths and sizes.

if [ -z "$1" ]; then
    echo "Usage: $0 <target_directory_path>"
    exit 1
fi

TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

echo "=================================================="
echo "Scanning for files larger than 10MB in: $TARGET_DIR"
echo "=================================================="

# Find files larger than 10MB (+10000k or +10M depending on find flavor)
find "$TARGET_DIR" -type f -size +10000k -exec du -sh {} \;

echo "=================================================="
echo "Scan complete."
