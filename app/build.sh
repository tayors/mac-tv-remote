#!/bin/zsh
set -eu
REMOTE_SOURCE_DIR="${0:A:h}"
REMOTE_APP_PATH="${1:-$HOME/Applications/Mac TV Remote.app}"
mkdir -p "$REMOTE_APP_PATH/Contents/MacOS" "$REMOTE_APP_PATH/Contents/Resources"
xcrun swiftc "$REMOTE_SOURCE_DIR/Remote.swift" -target "$(uname -m)-apple-macosx13.0" -O -o "$REMOTE_APP_PATH/Contents/MacOS/TVRemote" -framework AppKit -framework SwiftUI
cp "$REMOTE_SOURCE_DIR/remote_bridge.py" "$REMOTE_SOURCE_DIR/tv.py" "$REMOTE_APP_PATH/Contents/Resources/"
cat > "$REMOTE_APP_PATH/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>TVRemote</string>
<key>CFBundleIdentifier</key><string>io.github.tayors.mactvremote</string>
<key>CFBundleName</key><string>Mac TV Remote</string>
<key>CFBundleDisplayName</key><string>Mac TV Remote</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSLocalNetworkUsageDescription</key><string>TV Remote connects to your TV to show its status and send remote-control commands.</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
if [[ -d "$REMOTE_APP_PATH/Contents/Resources/__pycache__" ]]; then
    /bin/rm -r "$REMOTE_APP_PATH/Contents/Resources/__pycache__"
fi
codesign --force --sign - "$REMOTE_APP_PATH"
print -r -- "Built $REMOTE_APP_PATH"
