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
#   本工程使用「固定路径共享配置」，不依赖 App Group，因此免费 Apple ID 也能打包。
#   但是——Finder Sync 扩展必须「带 Team 的正式开发签名」才能被系统注入 Finder；
#   若用 Xcode 26 的 “Sign to Run Locally”（ad-hoc，无 Team）签名，扩展不会被 Finder
#   加载，右键菜单就永远出不来。所以请务必用你的 Apple ID（免费即可）Team 签名：
#   - 在 Xcode 的 Signing & Capabilities 里为两个 target 选中你的 Apple ID 作为 Team；
#   - 或用本脚本传入 Team： DEVELOPMENT_TEAM=你的TeamID ./build.sh dmg
#
# 用法：
#   ./build.sh app                # 用选中/传入的 Team 签名，产出 build/QuickRight.app
#   ./build.sh dmg                # 用选中/传入的 Team 签名，产出 build/QuickRight.dmg
#   DEVELOPMENT_TEAM=XXXX ./build.sh dmg   # 显式指定免费/付费 Team ID 签名
#
# 说明：
#   - 脚本会先 xcodegen generate 重建工程，再 archive
#   - 公证(notarization)需付费 Developer ID + App Store Connect API Key
# =====================================================================
set -euo pipefail

TEAM_ID="${DEVELOPMENT_TEAM:-}"
# 显式指定签名证书类型。本机若只有“Apple Development”（跨平台开发证书）而 Xcode
# 默认要“Mac Development”，可设 CODE_SIGN_IDENTITY="Apple Development" 强制使用它。
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
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
#    必须带 Team 签名（在 Xcode 选中你的 Apple ID，或用 DEVELOPMENT_TEAM 传入）。
#    不传 Team 时走 ad-hoc 本地签名：主程序能跑，但 Finder 扩展不会被加载。
if [[ -z "$TEAM_ID" ]]; then
  echo "⚠️  未指定 DEVELOPMENT_TEAM，将走 ad-hoc 本地签名。" >&2
  echo "    主程序可运行，但 Finder Sync 扩展不会被系统加载，右键菜单不会出现的！" >&2
  echo "    请在 Xcode 为两个 target 选中你的 Apple ID（免费即可）后重试，或用：" >&2
  echo "    DEVELOPMENT_TEAM=你的TeamID ./build.sh dmg" >&2
fi
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
if [[ -n "$SIGN_IDENTITY" ]]; then
  ARCHIVE_ARGS+=(CODE_SIGN_IDENTITY="$SIGN_IDENTITY")
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
  echo "▶ 打包 DMG（标准布局：App + 拖到应用程序）"
  rm -rf build/dist && mkdir -p build/dist
  cp -R "$APP_IN_ARCHIVE" build/dist/
  # 提供“应用程序”快捷方式，用户可直接拖拽安装
  ln -s /Applications build/dist/Applications
  rm -f build/QuickRight.dmg
  hdiutil create -volname QuickRight -srcfolder build/dist -ov -format UDZO build/QuickRight.dmg
  echo "✅ 已生成 build/QuickRight.dmg（双击打开后把 QuickRight.app 拖到 Applications 即可）"
  if [[ -z "$TEAM_ID" ]]; then
    echo "⚠️  当前为 ad-hoc 本地签名：主程序能用，但右键菜单扩展不会被 Finder 加载。"
    echo "    请用你的 Apple ID Team 重新签名：DEVELOPMENT_TEAM=你的TeamID ./build.sh dmg"
  else
    echo "   已用 Team($TEAM_ID) 签名，扩展可被 Finder 加载（仍需在系统设置中手动启用）。"
  fi
else
  echo "▶ 拷贝 .app"
  rm -rf build/QuickRight.app
  cp -R "$APP_IN_ARCHIVE" build/QuickRight.app
  echo "✅ 已生成 build/QuickRight.app"
  echo "   首次使用：系统设置 → 隐私与安全性 → 扩展 → Finder 扩展，启用「右键快捷」"
fi
