#!/bin/bash

# Simple script to recursively scan a folder for machine learning model files.
# It prints the path and file size without performing any copying.

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
echo "Scanning for AI / Machine Learning Models in: $TARGET_DIR"
echo "=================================================="

# Extensions to scan
find "$TARGET_DIR" -type f \( \
    -name "*.mlmodel" -o \
    -name "*.mlmodelc" -o \
    -name "*.mlpackage" -o \
    -name "*.onnx" -o \
    -name "*.tflite" -o \
    -name "*.pt" -o \
    -name "*.pth" -o \
    -name "*.bin" -o \
    -name "*.weights" -o \
    -name "*.param" \
\) -exec du -sh {} \;

echo "=================================================="
echo "Scan complete."
