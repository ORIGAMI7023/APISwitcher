#!/bin/bash

# APISwitcher macOS App Build Script
# 构建 Swift Package 并打包为 macOS 应用程序

set -e

APP_NAME="APISwitcher"
BUILD_DIR=".build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building $APP_NAME..."

# 1. 编译 Swift Package
swift build -c release

echo "📦 Creating app bundle..."

# 2. 清理旧的 app bundle
rm -rf "$APP_BUNDLE"

# 3. 创建 app bundle 目录结构
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 4. 复制可执行文件
cp "$BUILD_DIR/release/$APP_NAME" "$MACOS_DIR/"

# 5. 复制应用图标
if [ -f "APISwitcher/Resources/AppIcon.icns" ]; then
    cp "APISwitcher/Resources/AppIcon.icns" "$RESOURCES_DIR/"
    echo "📱 App icon copied"
fi

# 6. 创建 Info.plist (使用实际值替换变量)
cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>APISwitcher</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.origami.apiswitcher</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>API Switcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. All rights reserved.</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 7. 复制资源文件（如果存在）
if [ -d "$BUILD_DIR/release/APISwitcher_APISwitcher.bundle" ]; then
    cp -R "$BUILD_DIR/release/APISwitcher_APISwitcher.bundle"/* "$RESOURCES_DIR/" 2>/dev/null || true
fi

echo "✅ Build complete: $APP_BUNDLE"
echo ""
echo "To run the app:"
echo "  open $APP_BUNDLE"
echo ""
echo "To install to Applications:"
echo "  cp -R $APP_BUNDLE /Applications/"
