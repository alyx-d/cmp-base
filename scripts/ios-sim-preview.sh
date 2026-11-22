#!/bin/bash
# iOS 模拟器预览：构建 .app → 启动模拟器 → 安装 → 启动 → 截图
#
# 用法：
#   ./scripts/ios-sim-preview.sh                # 默认 iPhone 17，截图到 docs/ios-simulator.png
#   ./scripts/ios-sim-preview.sh "iPhone 17 Pro" /tmp/shot.png
#
# 前置条件：
#   - Xcode 已安装且 iOS 模拟器 runtime 已下载（xcodebuild -downloadPlatform iOS）
#   - 模拟器上装 app 不需要签名，故这里用 CODE_SIGNING_ALLOWED=NO
set -o pipefail
cd "$(dirname "$0")/.."

PROJ=iosApp/iosApp.xcodeproj
BUNDLE=com.dicek.app
DEV="${1:-iPhone 17}"
SHOT="${2:-docs/ios-simulator.png}"
DERIVED=/tmp/cmpdd

echo "== 1/5 检查 runtime =="
xcrun simctl list runtimes | grep -q "iOS" || {
  echo "没有 iOS runtime，请先执行：xcodebuild -downloadPlatform iOS" >&2
  exit 1
}

echo "== 2/5 构建 .app =="
# 注意：项目只保留 arm64（CMP 1.13 不再发布 iosX64），
# 必须显式指定 ARCHS，否则 generic 目标会连 x86_64 一起构建并报
# "Unknown iOS simulator arch: 'x86_64'"
xcodebuild -project "$PROJ" -scheme iosApp -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED" \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES VALID_ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build > /tmp/iosbuild.log 2>&1 || {
    grep -E "error:" /tmp/iosbuild.log | head -10 >&2
    echo "构建失败，完整日志见 /tmp/iosbuild.log" >&2
    exit 1
  }
APP=$(ls -d "$DERIVED"/Build/Products/Debug-iphonesimulator/*.app | head -1)
echo "   $APP"

echo "== 3/5 启动模拟器 =="
UDID=$(xcrun simctl list devices available | grep -F "$DEV (" | grep -o "[0-9A-F-]\{36\}" | head -1)
if [ -z "$UDID" ]; then
  RUNTIME=$(xcrun simctl list runtimes | grep -o "com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]*" | head -1)
  DEVTYPE=$(xcrun simctl list devicetypes | grep -F "$DEV (" | grep -o "com.apple.CoreSimulator.SimDeviceType.[A-Za-z0-9-]*" | head -1)
  UDID=$(xcrun simctl create "$DEV" "$DEVTYPE" "$RUNTIME")
fi
echo "   $DEV = $UDID"
xcrun simctl boot "$UDID" 2>/dev/null
open -a Simulator
xcrun simctl bootstatus "$UDID" -b > /dev/null 2>&1

echo "== 4/5 安装并启动 =="
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE"
sleep 10

echo "== 5/5 截图 =="
mkdir -p "$(dirname "$SHOT")"
xcrun simctl io "$UDID" screenshot "$SHOT"
echo "   已保存：$SHOT"
