#!/bin/bash
set -e

# --- Configuration ---
SOURCE_REPO="https://github.com/cloudnative-pg/cloudnative-pg.git"
SOURCE_DOCS_PATH="docs/src"

VERSION_ARG="$1"      
DEST_FOLDER="$2"      

if [ -z "$VERSION_ARG" ] || [ -z "$DEST_FOLDER" ]; then
    echo "Usage: $0 <version_arg> <destination_folder>"
    exit 1
fi

echo "=== Importing CloudNativePG Docs for version: $VERSION_ARG ==="

TEMP_DIR=$(mktemp -d)
GIT_REF=""
TARGET_DOCS_FOLDER="$DEST_FOLDER"

# -------------------------
# 1. Determine version type
# -------------------------
if [ "$VERSION_ARG" = "main" ]; then
    GIT_REF="main"
    echo "→ Building DEV docs from main branch."
elif [[ "$VERSION_ARG" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?$ ]]; then
    GIT_REF="v$VERSION_ARG"
    MINOR_VERSION=$(echo "$VERSION_ARG" | cut -d'.' -f1,2)
    TARGET_DOCS_FOLDER="versioned_docs/$MINOR_VERSION"
    echo "→ Building docs for release $VERSION_ARG → minor $MINOR_VERSION"
else
    echo "Invalid version format: $VERSION_ARG"
    exit 1
fi

# -------------------------
# 2. Clone source repo
# -------------------------
git clone --depth 1 --branch "$GIT_REF" "$SOURCE_REPO" "$TEMP_DIR/source"

SOURCE_PATH="$TEMP_DIR/source/$SOURCE_DOCS_PATH"

mkdir -p "$TARGET_DOCS_FOLDER"
rm -rf "$TARGET_DOCS_FOLDER"/*

rsync -a "$SOURCE_PATH/" "$TARGET_DOCS_FOLDER/"

# -------------------------
# 3. Replace mkdocs → Docusaurus syntax (Phase 1)
# -------------------------
# Example replacements
find "$TARGET_DOCS_FOLDER" -type f -name "*.md" -exec sed -i \
    -e 's/!!! note/:::note/g' \
    -e 's/!!! warning/:::warning/g' \
    -e 's/!!! tip/:::tip/g' {} \;

if [[ "$VERSION_ARG" =~ -rc[0-9]+$ ]]; then
    echo "→ Marking this version as preview (RC)."
fi

rm -rf "$TEMP_DIR"
echo "=== Import completed → Files in $TARGET_DOCS_FOLDER ==="
