#!/usr/bin/env bash
#
# QuickRight 一键打包脚本
# =====================================================================
# 前置条件（仅首次需要，需你本人在终端执行）：
#   1) 同意 Xcode 许可协议（需管理员密码）：
#        sudo xcodebuild -license accept
#   2) 安装 Xcode 命令行工具（已含 xcodebuild）
#
# 关于签名（重要）：
#   本工程使用「固定路径共享配置」，不依赖 App Group，因此
#   免费 Apple ID 也能打包。Xcode 26 提供 “Sign to Run Locally”
#   （ad-hoc 本地签名），无需任何开发者账号即可 archive 出可
#   在本机运行的 .app（含 Finder 扩展）。
#   - 不填 DEVELOPMENT_TEAM：走本地签名（免费账号即可）
#   - 填了付费 Team ID：使用开发/分发证书签名
#
# 用法：
#   ./build.sh app                # 本地签名，产出 build/QuickRight.app
#   ./build.sh dmg                # 本地签名，产出 build/QuickRight.dmg
#   DEVELOPMENT_TEAM=XXXX ./build.sh dmg   # 付费账号：用 Team 证书签名
#
# 说明：
#   - 脚本会先 xcodegen generate 重建工程，再 archive
#   - 公证(notarization)需付费 Developer ID + App Store Connect API Key
# =====================================================================
set -euo pipefail

TEAM_ID="${DEVELOPMENT_TEAM:-}"
MODE="${1:-app}"   # app | dmg

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

# 2) Archive
#    不传 DEVELOPMENT_TEAM 时，Xcode 26 自动使用 “Sign to Run Locally” 本地签名
ARCHIVE_ARGS=(
  -project QuickRight.xcodeproj
  -scheme QuickRight
  -configuration Release
  -archivePath build/Archive/QuickRight.xcarchive
  ARCHS=arm64
  ONLY_ACTIVE_ARCH=NO
  CODE_SIGN_STYLE=Automatic
  clean archive
)
if [[ -n "$TEAM_ID" ]]; then
  ARCHIVE_ARGS+=(DEVELOPMENT_TEAM="$TEAM_ID")
fi

echo "▶ Archive (scheme=QuickRight, configuration=Release)"
rm -rf build/Archive
xcodebuild "${ARCHIVE_ARGS[@]}"

# 3) 取出 .app
APP_IN_ARCHIVE="build/Archive/QuickRight.xcarchive/Products/Applications/QuickRight.app"
if [[ ! -d "$APP_IN_ARCHIVE" ]]; then
  echo "❌ 未在归档中找到 QuickRight.app" >&2
  exit 1
fi

if [[ "$MODE" == "dmg" ]]; then
  echo "▶ 打包 DMG"
  rm -rf build/dist && mkdir -p build/dist
  cp -R "$APP_IN_ARCHIVE" build/dist/
  rm -f build/QuickRight.dmg
  hdiutil create -volname QuickRight -srcfolder build/dist -ov -format UDZO build/QuickRight.dmg
  echo "✅ 已生成 build/QuickRight.dmg"
  if [[ -z "$TEAM_ID" ]]; then
    echo "   注意：当前为本地(ad-hoc)签名，分发给他人的 Mac 会被 Gatekeeper 拦截；"
    echo "   本机自测可用。对外分发需用付费 Developer ID 签名并公证。"
  fi
else
  echo "▶ 拷贝 .app"
  rm -rf build/QuickRight.app
  cp -R "$APP_IN_ARCHIVE" build/QuickRight.app
  echo "✅ 已生成 build/QuickRight.app"
  echo "   首次使用：系统设置 → 隐私与安全性 → 扩展 → Finder 扩展，启用「右键快捷」"
fi
