#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="ClashGlass"
BUNDLE_ID="com.maxchang.ClashGlass"
MIN_SYSTEM_VERSION="15.0"
APP_VERSION="${APP_VERSION:-0.1.0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
CORE_BINARY="$ROOT_DIR/core/mihomo"
GEO_DATA_SOURCE="$ROOT_DIR/runtime-assets"
GEO_DATA_DESTINATION="$APP_RESOURCES/GeoData"
APP_ICON_SOURCE="$ROOT_DIR/Assets/AppIcon.icns"

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  /usr/bin/osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
  for _ in {1..20}; do
    pgrep -x "$APP_NAME" >/dev/null 2>&1 || break
    sleep 0.1
  done
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
fi

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
mkdir -p "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
if [[ -x "$CORE_BINARY" ]]; then
  cp "$CORE_BINARY" "$APP_RESOURCES/mihomo"
  chmod +x "$APP_RESOURCES/mihomo"
else
  echo "warning: Mihomo core is missing; run ./script/bootstrap.sh" >&2
fi
if [[ -d "$GEO_DATA_SOURCE" ]]; then
  mkdir -p "$GEO_DATA_DESTINATION"
  while IFS= read -r asset; do
    cp "$asset" "$GEO_DATA_DESTINATION/"
  done < <(find "$GEO_DATA_SOURCE" -maxdepth 1 -type f -print)
fi
if [[ -f "$APP_ICON_SOURCE" ]]; then
  cp "$APP_ICON_SOURCE" "$APP_RESOURCES/AppIcon.icns"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>Clash Glass</string>
  <key>CFBundleDisplayName</key>
  <string>Clash Glass</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
