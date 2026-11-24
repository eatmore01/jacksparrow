#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="jacksparrow"
DEST_DIR="${INSTALL_DIR:-/Applications}"
DEST="$DEST_DIR/$APP_NAME.app"
BUILT="$ROOT/build/$APP_NAME.app"

"$ROOT/build.sh" >/dev/null

if [ ! -d "$BUILT" ]; then
    echo "build failed: $BUILT not found" >&2
    exit 1
fi

if [ ! -w "$DEST_DIR" ]; then
    echo "$DEST_DIR is not writable" >&2
    exit 1
fi

pkill -f "$DEST/Contents/MacOS/$APP_NAME" 2>/dev/null || true
sleep 1

rm -rf "$DEST"
cp -R "$BUILT" "$DEST"
open "$DEST"

echo "$DEST"
