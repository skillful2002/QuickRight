#!/usr/bin/env bash
#
# QuickRight 一键打包脚本
# =====================================================================
# 前置条件（仅首次需要，需你本人在终端执行）：
#   1) 同意 Xcode 许可协议（需管理员密码）：
#        sudo xcodebuild -license accept
#   2) Xcode → 设置 → 账户，登录你的 Apple ID
#        - 免费账号可做「开发签名」，App 仅能在你这台 Mac 上运行
#        - 付费 Developer Program 才能在后台注册 App Group 并做 Developer ID 分发
#   3) 开发者后台(https://developer.apple.com)注册 App Group：
#        group.tech.newxin-quickright.app
#      （本仓库已启用该 App Group，Xcode 自动签名会生成对应描述文件）
#
# 用法：
#   DEVELOPMENT_TEAM=你的10位TeamID ./build.sh app   # 本机开发签名，产出 QuickRight.app
#   DEVELOPMENT_TEAM=你的10位TeamID ./build.sh dmg   # Developer ID 签名，产出 QuickRight.dmg
#
# 说明：
#   - 脚本会先 xcodegen generate 重建工程，再 archive
#   - app 模式：直接从 xcarchive 拷贝 .app（开发证书签名，仅本机可用）
#   - dmg 模式：用 developer-id 导出并打成 .dmg（需付费账号 + Developer ID 证书）
#   - 公证(notarization)需 App Store Connect API Key，见脚本末尾注释
# =====================================================================
set -euo pipefail

TEAM_ID="${DEVELOPMENT_TEAM:-}"
MODE="${1:-app}"   # app | dmg

if [[ -z "$TEAM_ID" ]]; then
  echo "❌ 缺少 Team ID。用法：" >&2
  echo "   DEVELOPMENT_TEAM=你的10位TeamID ./build.sh [app|dmg]" >&2
  exit 1
fi

cd "$(dirname "$0")"

# 0) 依赖检查
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "❌ 请先安装 xcodegen: brew install xcodegen" >&2
  exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "❌ 未找到 xcodebuild，请确认 Xcode 命令行工具已安装且已同意许可协议" >&2
  exit 1
fi

# 1) 生成 Xcode 工程
echo "▶ 生成 Xcode 工程 (xcodegen generate)"
xcodegen generate

# 2) 准备导出选项
if [[ "$MODE" == "dmg" ]]; then
  METHOD="developer-id"
else
  METHOD="mac-application"
fi

mkdir -p build
cat > build/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>${METHOD}</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
</dict>
</plist>
PLIST

# 3) Archive（仅编译 arm64，Apple Silicon；如需通用可改为 "arm64 x86_64"）
echo "▶ Archive (scheme=QuickRight, configuration=Release)"
rm -rf build/Archive build/Export
xcodebuild -project QuickRight.xcodeproj \
  -scheme QuickRight \
  -configuration Release \
  -archivePath build/Archive/QuickRight.xcarchive \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  clean archive

# 4) 取出 .app
APP_IN_ARCHIVE="build/Archive/QuickRight.xcarchive/Products/Applications/QuickRight.app"
if [[ ! -d "$APP_IN_ARCHIVE" ]]; then
  echo "❌ 未在归档中找到 QuickRight.app" >&2
  exit 1
fi

if [[ "$MODE" == "dmg" ]]; then
  echo "▶ 用 developer-id 导出 .app"
  xcodebuild -exportArchive \
    -archivePath build/Archive/QuickRight.xcarchive \
    -exportOptionsPlist build/ExportOptions.plist \
    -exportPath build/Export
  APP="$(find build/Export -name 'QuickRight.app' -maxdepth 2 | head -1)"
  echo "▶ 打包 DMG"
  rm -f build/QuickRight.dmg
  hdiutil create -volname QuickRight -srcfolder "$APP" -ov -format UDZO build/QuickRight.dmg
  echo "✅ 已生成 build/QuickRight.dmg"
  echo "   提示：对外分发前建议公证："
  echo "   xcrun notarytool submit build/QuickRight.dmg --keychain-profile <profile> --wait"
else
  echo "▶ 拷贝开发签名版 .app"
  rm -rf build/QuickRight.app
  cp -R "$APP_IN_ARCHIVE" build/QuickRight.app
  echo "✅ 已生成 build/QuickRight.app"
  echo "   首次使用：系统设置 → 隐私与安全性 → 扩展 → Finder 扩展，启用「右键快捷」"
fi
