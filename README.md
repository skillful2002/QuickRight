# 右键快捷 (QuickRight)

开源免费的 macOS 右键增强工具，解决 Finder 无法右键「新建文件」的痛点，并附带复制路径、在终端/IDE 打开、常用目录等高频功能。

- 主程序是**标准窗口 App**：双击运行即弹出设置界面（不常驻菜单栏）。
- 在 Finder 右键菜单中内置「设置」项，点击即可唤起主程序。
- 配置变更实时生效，无需重启 Finder。
- 最低支持 **macOS 14 (Sonoma)**，Swift 6 + SwiftUI 实现。

## ⚠️ 重要：免费账号无法启用右键菜单（实测结论）

**现状**：本工具的全部代码已完成，**设置窗口功能在免费账号下完全可用**（双击运行 → 配置新建格式 / 应用 / 常用目录 / 模板）；但**右键菜单功能需要付费的 Apple Developer Program（$99/年）才能生效**，免费 Apple ID 做不到。原因如下：

- macOS 15 (Sequoia) 及之后的系统，Finder Sync 扩展（右键菜单注入的唯一官方机制）由 `pluginkit` 管理，**只收录「Apple 颁发的证书链」签名的扩展**（Developer ID / Apple Development / Mac App Store）。
- 实测三种免费路径**全部无法让扩展被加载**：

| 签名方式 | 扩展能否被系统收录/加载 | 右键菜单 |
|---------|----------------------|---------|
| ad-hoc 本地签名（Sign to Run Locally） | ❌ 否 | ❌ |
| 免费 Apple ID 的 Apple Development 签名（装 /Applications） | ❌ 否 | ❌ |
| 免费 Apple ID + Xcode ⌘R 开发会话（macOS 26 实测） | ❌ 否 | ❌ |
| 自签名证书 + 加入系统信任根 | ❌ 否 | ❌ |
| **付费 Developer Program → Developer ID 签名（+公证）** | ✅ 是 | ✅ |

- **结论**：要让右键菜单出现，必须使用 **Developer ID 证书**签名（需要付费开发者账号）。这是 WPS、群晖、MacZip 等所有同类右键工具的统一做法，是系统安全策略，无法通过代码绕过。
- 已购买付费账号后，只需把构建签名切换为 Developer ID（见下文「付费账号出包」），右键菜单即可正常使用，且可分发到任何 Mac。

> 验证扩展是否被系统收录的命令（付费签名后应能看到本扩展的 UUID）：
> ```bash
> pluginkit -mAD -p com.apple.FinderSync -vvv | grep -i quickright
> ```

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
xcodegen generate          # 生成 QuickRight.xcodeproj（已内置 DEVELOPMENT_TEAM 配置）
open QuickRight.xcodeproj
```

在 Xcode 中：
1. 选中 `QuickRight` scheme，⌘R 运行即可看到设置窗口。本工程使用固定路径（`~/Library/Application Support/QuickRight/`）共享配置，**不需要 App Group**。
2. **签名说明**：
   - **免费账号（仅能用设置窗口）**：在两个 target 的 `Signing & Capabilities` 里选中你的 Apple ID 做开发签名即可；不要走 "Sign to Run Locally"（ad-hoc）——那样主程序能跑，但扩展同样不被加载。
   - **付费账号（右键菜单可用）**：使用 Developer ID 证书签名，并建议公证（见下文）。
3. 运行 `QuickRight` scheme。

> 一键打包脚本 `build.sh`：
> ```bash
> ./build.sh app     # 产出 build/QuickRight.app（使用工程内置 Team 签名）
> ./build.sh dmg     # 产出 build/QuickRight.dmg
> DEVELOPMENT_TEAM=你的TeamID ./build.sh dmg   # 显式指定 Team
> ```
> 注意：`xcodegen generate` 会重生成工程，必须把 `DEVELOPMENT_TEAM` 写进 `project.yml`（本仓库已内置），否则重生成会冲掉 Xcode 里手选的 Team，Archive 会静默退化成 ad-hoc 签名。

### 方式二：手动在 Xcode 创建

1. 新建 macOS App（SwiftUI）工程，产品名 `QuickRight`。
2. `File → New → Target → Finder Sync Extension`，产品名 `QuickRightFinder`，Principal Class 为 `FinderSync`。
3. 把本仓库 `Shared/`、`QuickRight/`、`QuickRightFinder/` 下的源文件加入对应 target（Shared 两个 target 都加）。
4. 两个 target 均**无需**开启 App Group（本工程用固定路径共享配置）。
5. 把 `QuickRight/QuickRight.entitlements` 与 `QuickRightFinder/QuickRightFinder.entitlements` 设为对应 target 的 Entitlements 文件。

## 付费账号出包（右键菜单可用的关键）

1. 加入 **Apple Developer Program**（https://developer.apple.com/programs/ ，$99/年）。
2. Xcode → Settings → Accounts → 登录你的 Apple ID（付费账号）→ Manage Certificates → **+ → Developer ID Application**（生成 Developer ID 证书）。
3. 两个 target 的 Signing & Capabilities 选择你的 Team，签名证书选 **Developer ID**（Distribution）。
4. 出包：
   - `Product → Archive` → 归档后从 Organizer 的 `Products/Applications` 取出 `QuickRight.app`（或右键归档 → 显示包内容）。
   - 或命令行：`DEVELOPMENT_TEAM=你的TeamID ./build.sh dmg`。
5. 分发前建议公证（notarization）：`xcrun notarytool submit`（需 App Store Connect API Key，参照 Apple 文档），公证后任意 Mac 双击即用，无 Gatekeeper 拦截。

## 启用 Finder 扩展（付费签名后，缺一不可）

1. **App 必须装在 `/Applications`**。装在其他位置（下载、桌面、build 目录）系统不会注册其扩展。
2. **手动启用扩展**：
   - macOS 15.2+：系统设置 → 通用 → 登录项与扩展 → **文件提供方(File Providers)**，在「右键快捷」后打开开关。
   - macOS 14 / 15.0–15.1：系统设置 → 隐私与安全性 → 扩展 → **Finder 扩展**，勾选「右键快捷」。
   - 若系统设置里**看不到**「右键快捷」，说明扩展没被收录：确认 App 在 `/Applications`，然后检查签名是否为 Developer ID（`codesign -dvv /Applications/QuickRight.app` 的 Authority 应为 Developer ID），再到「控制台」搜索 `QuickRightFinder` 看是否有“扩展已初始化”日志。
3. **重启访达**：按住 Option 右键点击 Dock 上的访达图标 → 重新启动（或 `killall Finder`）。
4. 在 Finder 任意位置或桌面右键，即可看到新增菜单。

> 命令行兜底（付费签名后仍不出现时用）：
> ```bash
> pluginkit -mAD -p com.apple.FinderSync -vvv   # 查看本扩展是否被收录及 UUID
> pluginkit -e "use" -u <上一步输出的UUID>      # 手动启用
> killall Finder
> ```

> 默认只监控用户主目录（桌面/下载/文档等）。如需在外接磁盘等位置也出现菜单，请开启「完全磁盘访问」并将 `FinderSync.swift` 中 `directoryURLs` 改为监控 `"/"`。

## 常见问题（FAQ）

**Q：双击 App 只看到 Dock 图标，没有窗口？**
已修复：窗口由 SwiftUI 原生生命周期管理（`WindowGroup`），正常双击即可弹出 540×440 设置窗口。若仍异常，先删除 `/Applications/QuickRight.app` 重新安装（LaunchServices 会缓存旧注册）。

**Q：系统设置「文件提供方」里出现多个 QuickRight？**
是历史安装残留的重复注册（build 目录 / Xcode DerivedData / 旧 dmg 卷 / 废纸篓里的旧包）。逐个清理：
```bash
LSREG=/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister
# 对每个非 /Applications 的旧 QuickRight.app 路径执行：
"$LSREG" -u "<旧路径>"
"$LSREG" -f /Applications/QuickRight.app   # 重新注册唯一实例
killall Finder
```

**Q：扩展已签名、已注册、已勾选，但右键还是没有菜单？**
用 `pluginkit -mAD -p com.apple.FinderSync -vvv | grep -i quickright` 检查：**查不到** = 签名不被系统接受（免费 Apple Development / ad-hoc / 自签名都会这样），需换 Developer ID 签名（见上文「付费账号出包」）。

## 未公证构建的说明

开源 MVP 阶段提供的是**未公证**构建。首次打开若被 Gatekeeper 拦截：
- 右键点击 App → 打开；或在 系统设置 → 隐私与安全性 中允许。
- 或执行 `sudo xattr -cr /Applications/QuickRight.app` 清除隔离标志。

后续若要干净分发，请使用付费的 Developer ID 进行签名与公证。

## 项目结构

```
Shared/        主程序与扩展共用的常量、数据模型、配置读写
QuickRight/    主程序：窗口 App + SwiftUI 设置界面（QuickRightApp.swift 为入口）
QuickRightFinder/  Finder Sync 扩展：注入右键菜单、执行动作
project.yml    XcodeGen 工程描述（含 DEVELOPMENT_TEAM 配置）
```

## 路线图

- P2：剪切/粘贴、复制到/移动到、隐藏/显示文件、彻底删除
- P3：图片转图标集、翻译、二维码、多语言、暗色细节打磨

## 许可证

[MIT](LICENSE)
