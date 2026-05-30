#!/bin/bash

# Simple script to scan files for audio, DSP, and AI framework keywords.
# It prints matching files and search terms.

if [ -z "$1" ]; then
    echo "Usage: $0 <target_directory_path>"
    exit 1
fi

TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

KEYWORDS="CoreML|AVAudioEngine|AudioKit|FFmpeg|ONNX|TensorFlow|PyTorch|STFT|iSTFT|phase vocoder|stem|chord|beat|tempo"

echo "=================================================="
echo "Scanning for Audio/AI Framework References in: $TARGET_DIR"
echo "=================================================="

# Search binary files and text configs for references
grep -rniI -E "$KEYWORDS" "$TARGET_DIR" --include=\*.plist --include=\*.json --include=\*.swift --include=\*.strings

echo "=================================================="
echo "Scan complete."
