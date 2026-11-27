#!/bin/zsh
set -euo pipefail

NAME="jacksparrow"
ROOT="${0:A:h}"
BUNDLE="$ROOT/build/$NAME.app"

cd "$ROOT"
swift build -c release --product "$NAME"

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$ROOT/.build/release/$NAME" "$BUNDLE/Contents/MacOS/$NAME"
cp "$ROOT/Resources/Info.plist" "$BUNDLE/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"
cp "$ROOT/Resources/StatusIcon.png" "$BUNDLE/Contents/Resources/StatusIcon.png"
cp "$ROOT/Resources/TimerIcon.png" "$BUNDLE/Contents/Resources/TimerIcon.png"
cp "$ROOT/Resources/ShlikerIcon.png" "$BUNDLE/Contents/Resources/ShlikerIcon.png"
cp "$ROOT/Resources/AlertSound.mp3" "$BUNDLE/Contents/Resources/AlertSound.mp3"
cp "$ROOT/Resources/NotesIcon.png" "$BUNDLE/Contents/Resources/NotesIcon.png"
printf 'APPL????' > "$BUNDLE/Contents/PkgInfo"

codesign --force --sign - --identifier "local.jacksparrow" --timestamp=none \
  -r='designated => identifier "local.jacksparrow"' "$BUNDLE" >/dev/null 2>&1

plutil -lint "$BUNDLE/Contents/Info.plist"
codesign --verify --verbose=1 "$BUNDLE"
codesign -d -r- "$BUNDLE" 2>&1 | tail -1
print "built: $BUNDLE"
