# 右键快捷 (QuickRight)

开源免费的 macOS 右键增强工具，解决 Finder 无法右键「新建文件」的痛点，并附带复制路径、在终端/IDE 打开、常用目录等高频功能。

- 主程序是**标准窗口 App**：双击运行即弹出设置界面（不常驻菜单栏）。
- 在 Finder 右键菜单中内置「设置」项，点击即可唤起主程序。
- 配置变更实时生效，无需重启 Finder。
- 最低支持 **macOS 14 (Sonoma)**，Swift 6 + SwiftUI 实现。

## 功能

| 功能 | 说明 |
|------|------|
| 右键新建文件 | 内置 txt/md/json/rtf/csv/docx/xlsx/pptx/py/sh 等；可自定义新增格式；支持「模板」模式（复制模板文件夹中 `template.<ext>` 的内容）；同名自动递增 |
| 复制路径 | 复制选中文件/文件夹的完整路径到剪贴板（多选换行） |
| 在以下应用打开 | 通过 Bundle ID 调用 终端/iTerm2/VSCode/Sublime 等，在当前文件夹打开 |
| 常用目录 | 右键快速在 Finder 打开用户配置的常用目录 |
| 设置 | 右键菜单底部「设置」唤起主程序配置窗口 |

## 构建与运行

### 方式一：XcodeGen（推荐）

```bash
brew install xcodegen
cd <本仓库目录>
xcodegen generate          # 生成 QuickRight.xcodeproj
open QuickRight.xcodeproj
```

在 Xcode 中：
1. 选中 `QuickRight` scheme 直接运行即可。本工程使用固定路径（`~/Library/Application Support/QuickRight/`）共享配置，**不需要 App Group**，因此免费 Apple ID 也能签名打包。
2. **必须用你的 Apple ID（免费即可）作为 Team 做“开发签名”**：在两个 target 的 `Signing & Capabilities` 里选中你的 Apple ID。注意：不要留空走 “Sign to Run Locally”（ad-hoc）签名——那样主程序能跑，但 **Finder Sync 扩展不会被系统加载**，右键菜单永远出不来。
3. 运行 `QuickRight` scheme。

> 已提供一键打包脚本 `build.sh`（免费账号可直接用）：
> ```bash
> ./build.sh app     # 本地签名，产出 build/QuickRight.app
> ./build.sh dmg     # 本地签名，产出 build/QuickRight.dmg
> # 付费账号可加 Team：DEVELOPMENT_TEAM=你的TeamID ./build.sh dmg
> ```

### 方式二：手动在 Xcode 创建

1. 新建 macOS App（SwiftUI）工程，产品名 `QuickRight`。
2. `File → New → Target → Finder Sync Extension`，产品名 `QuickRightFinder`，Principal Class 为 `FinderSync`。
3. 把本仓库 `Shared/`、`QuickRight/`、`QuickRightFinder/` 下的源文件加入对应 target（Shared 两个 target 都加）。
4. 两个 target 均**无需**开启 App Group（本工程用固定路径共享配置）。
5. 把 `QuickRight/QuickRight.entitlements` 与 `QuickRightFinder/QuickRightFinder.entitlements` 设为对应 target 的 Entitlements 文件。

## 启用 Finder 扩展（关键，缺一不可）

首次运行后右键菜单**不会自动出现**，必须满足以下全部条件：

1. **App 必须装在 `/Applications`**（或 `~/Applications`）。装在其他位置（下载、桌面、build 目录）系统不会注册其扩展。
2. **手动启用扩展**：
   - macOS 15.2+：系统设置 → 通用 → 登录项与扩展 → **文件提供方(File Providers)**，在「右键快捷」后打开开关。
   - macOS 14 / 15.0–15.1：系统设置 → 隐私与安全性 → 扩展 → **Finder 扩展**，勾选「右键快捷」。
   - 若系统设置的扩展列表里**根本看不到**「右键快捷」，说明扩展没被注册：先确认 App 在 `/Applications`，再到「控制台」搜索 `QuickRightFinder` 看是否有“扩展已初始化”日志（没有则说明签名不对，需换带 Team 的开发签名）。
3. **重启访达**：在访达中按住 Option 键右键点击 Dock 上的访达图标 → 重新启动访达（或直接 `killall Finder`）。
4. 在 Finder 任意位置或桌面右键，即可看到新增菜单。

> 若以上都做了仍不出现，可用命令行强制注册/启用（把路径换成你的实际路径）：
> ```bash
> pluginkit -a /Applications/QuickRight.app/Contents/PlugIns/QuickRightFinder.appex
> pluginkit -e use -i com.quickright.QuickRightFinder
> ```
> 然后重启访达。

> 默认只监控用户主目录（桌面/下载/文档等）。如需在外接磁盘等位置也出现菜单，请开启「完全磁盘访问」并将 `FinderSync.swift` 中 `directoryURLs` 改为监控 `"/"`。

## 未公证构建的说明

开源 MVP 阶段提供的是**未公证**构建。首次打开若被 Gatekeeper 拦截：
- 右键点击 App → 打开；或在 系统设置 → 隐私与安全性 中允许。
- 或执行 `sudo xattr -cr /Applications/QuickRight.app` 清除隔离标志。

后续若要干净分发，请使用付费的 Developer ID 进行签名与公证。

## 项目结构

```
Shared/        主程序与扩展共用的常量、数据模型、配置读写
QuickRight/    主程序：窗口 App + SwiftUI 设置界面
QuickRightFinder/  Finder Sync 扩展：注入右键菜单、执行动作
project.yml    XcodeGen 工程描述
```

## 路线图

- P2：剪切/粘贴、复制到/移动到、隐藏/显示文件、彻底删除
- P3：图片转图标集、翻译、二维码、多语言、暗色细节打磨

## 许可证

[MIT](LICENSE)
