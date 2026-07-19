#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

app_dir="build/Quote Companion.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"

rm -rf "$app_dir"
mkdir -p "$macos_dir" "$resources_dir/assets" "$resources_dir/assets/fonts"

swiftc QuoteCompanion.swift -o "$macos_dir/QuoteCompanion"
cp quotes.json "$resources_dir/quotes.json"
cp assets/cat_companion.png "$resources_dir/assets/cat_companion.png"
cp assets/cat_companion_hover.png "$resources_dir/assets/cat_companion_hover.png"
cp assets/cat_companion_nose_hover.png "$resources_dir/assets/cat_companion_nose_hover.png"
cp assets/cat_companion_idle_ears_back.png "$resources_dir/assets/cat_companion_idle_ears_back.png"
cp assets/pawprint.svg "$resources_dir/assets/pawprint.svg"
cp assets/fonts/Dosis-Variable.ttf "$resources_dir/assets/fonts/Dosis-Variable.ttf"
cp assets/fonts/ZenLoop-Regular.ttf "$resources_dir/assets/fonts/ZenLoop-Regular.ttf"

cat > "$contents_dir/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>QuoteCompanion</string>
  <key>CFBundleIdentifier</key>
  <string>local.quote-companion</string>
  <key>CFBundleName</key>
  <string>Quote Companion</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

open -n "$app_dir"
