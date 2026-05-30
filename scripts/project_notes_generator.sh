#!/bin/bash

# Simple script to generate a folder structure tree and save notes.

if [ -z "$1" ]; then
    # Default to current directory's parent (assuming running from scripts/)
    TARGET_DIR="$(dirname "$(pwd)")"
else
    TARGET_DIR="$1"
fi

echo "=================================================="
echo "Generating Project Structure Tree for: $TARGET_DIR"
echo "=================================================="

# Check if tree command is available, fallback to find/sed
if command -v tree &> /dev/null; then
    tree "$TARGET_DIR" -I "node_modules|build|.dart_tool|.git|ios/Pods" > "$TARGET_DIR/PROJECT_TREE.txt"
else
    echo "music_stem_studio/" > "$TARGET_DIR/PROJECT_TREE.txt"
    find "$TARGET_DIR" -maxdepth 4 -not -path '*/.*' -not -path '*flutter_app/.dart_tool*' -not -path '*flutter_app/build*' -not -path '*ios/Pods*' | sed -e "s#$TARGET_DIR##" -e 's#[^/]*/#├── #g' >> "$TARGET_DIR/PROJECT_TREE.txt"
fi

echo "Project structure generated successfully and written to PROJECT_TREE.txt."
