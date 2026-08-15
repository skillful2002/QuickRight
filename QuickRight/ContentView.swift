import SwiftUI
import UniformTypeIdentifiers

/// 主设置界面：用 TabView 组织「新建文件 / 打开应用 / 常用目录 / 模板 / 关于」。
struct ContentView: View {
    @EnvironmentObject var store: ConfigStore

    var body: some View {
        TabView {
            FormatsView()
                .tabItem { Label("新建文件", systemImage: "doc.badge.plus") }
            AppsView()
                .tabItem { Label("打开应用", systemImage: "terminal") }
            DirsView()
                .tabItem { Label("常用目录", systemImage: "folder") }
            TemplateView()
                .tabItem { Label("模板", systemImage: "doc.on.doc") }
            AboutView()
                .tabItem { Label("关于", systemImage: "gear") }
        }
        .frame(width: 540, height: 440)
        .padding(8)
    }
}

// MARK: - 新建文件格式管理

struct FormatsView: View {
    @EnvironmentObject var store: ConfigStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("右键「新建文件」列出的格式。点「+ 添加格式」自定义；勾选「模板」则新建时复制模板文件夹中 template.<ext> 的内容。")
                .font(.caption).foregroundStyle(.secondary)
            List {
                ForEach($store.config.formats) { $fmt in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("名称", text: $fmt.name).frame(width: 130)
                            TextField("扩展名(不含.)", text: $fmt.ext).frame(width: 90)
                            Toggle("用模板", isOn: $fmt.useTemplate)
                            Spacer()
                        }
                        TextField("默认内容（未勾模板时写入）", text: $fmt.content)
                    }
                }
                .onDelete { store.config.formats.remove(atOffsets: $0) }
            }
            HStack {
                Button("+ 添加格式") {
                    store.config.formats.append(FileFormat(name: "新格式", ext: "txt"))
                }
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - 外部应用管理

struct AppsView: View {
    @EnvironmentObject var store: ConfigStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("右键「在以下应用打开」列表，点击当前文件夹即可用所选 App 打开。")
                .font(.caption).foregroundStyle(.secondary)
            List {
                ForEach($store.config.externalApps) { $app in
                    HStack {
                        TextField("名称", text: $app.name).frame(width: 160)
                        TextField("Bundle ID", text: $app.bundleID).frame(width: 240)
                    }
                }
                .onDelete { store.config.externalApps.remove(atOffsets: $0) }
            }
            HStack {
                Button("+ 添加应用") {
                    store.config.externalApps.append(ExternalApp(name: "新应用", bundleID: ""))
                }
                Button("选择 .app…") {
                    guard let url = chooseApp() else { return }
                    let name = url.deletingPathExtension().lastPathComponent
                    if let bid = Bundle(url: url)?.bundleIdentifier {
                        store.config.externalApps.append(ExternalApp(name: name, bundleID: bid))
                    }
                }
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - 常用目录管理

struct DirsView: View {
    @EnvironmentObject var store: ConfigStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("右键「常用目录」快速在 Finder 中打开。")
                .font(.caption).foregroundStyle(.secondary)
            List {
                ForEach($store.config.quickDirs) { $dir in
                    HStack {
                        TextField("名称", text: $dir.name).frame(width: 140)
                        TextField("路径", text: $dir.path).frame(width: 250)
                        Button("选择…") {
                            if let url = chooseFolder() {
                                dir.path = url.path
                            }
                        }
                    }
                }
                .onDelete { store.config.quickDirs.remove(atOffsets: $0) }
            }
            HStack {
                Button("+ 添加目录") {
                    store.config.quickDirs.append(QuickDir(name: "新目录", path: NSHomeDirectory()))
                }
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - 模板文件夹

struct TemplateView: View {
    @EnvironmentObject var store: ConfigStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("模板文件夹：某格式勾选「用模板」后，新建文件会复制该文件夹下 template.<ext> 的内容（例如 template.md）。")
                .font(.caption).foregroundStyle(.secondary)
            if let p = store.config.templateFolderPath {
                Text("当前：\(p)").font(.caption)
            } else {
                Text("未设置").font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Button("选择模板文件夹…") {
                    guard let url = chooseFolder() else { return }
                    do {
                        let bm = try url.bookmarkData(
                            options: .withSecurityScope,
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                        store.config.templateFolderBookmark = bm
                        store.config.templateFolderPath = url.path
                    } catch {
                        NSLog("QuickRight: 创建安全书签失败 \(error.localizedDescription)")
                    }
                }
                Button("清除") {
                    store.config.templateFolderBookmark = nil
                    store.config.templateFolderPath = nil
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - 关于 / 启用指引

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("右键快捷 (QuickRight)").font(.headline)
            Text("开源免费的 macOS 右键增强工具，解决 Finder 无法右键新建文件的痛点。")
            Divider()
            Text("启用步骤：")
            Text("1. 系统设置 → 隐私与安全性 → 扩展 → Finder 扩展，勾选「右键快捷」。")
            Text("2. 在 Finder 任意位置（或桌面）右键，即可看到新增的菜单。")
            Text("3. 双击本程序可随时打开此设置界面；右键菜单底部「设置」亦可唤起。")
            Spacer()
        }
        .padding()
    }
}

// MARK: - 文件选择辅助

func chooseFolder() -> URL? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    return panel.runModal() == .OK ? panel.url : nil
}

func chooseApp() -> URL? {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.application]
    panel.directoryURL = URL(fileURLWithPath: "/Applications")
    panel.allowsMultipleSelection = false
    return panel.runModal() == .OK ? panel.url : nil
}
