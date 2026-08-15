import Cocoa
import FinderSync

/// 右键菜单各项动作的实现。单例，菜单项的 target 指向它。
final class FileActions: NSObject {
    static let shared = FileActions()

    // 当前右键所在的目录（Finder 正在查看的文件夹）
    private func currentDirectory() -> URL? {
        FIFinderSyncController.default().targetedURL()
    }

    // MARK: - 菜单回调

    @objc func createFileFromMenu(_ sender: NSMenuItem) {
        guard let fmt = sender.representedObject as? FileFormat else { return }
        guard let dir = currentDirectory() else { return }
        let config = ConfigIO.load()
        FileActions.createFile(
            in: dir,
            format: fmt,
            templateBookmark: config?.templateFolderBookmark,
            base: config?.newFileNameBase ?? "untitled"
        )
    }

    @objc func copyPathsFromMenu(_ sender: NSMenuItem) {
        guard let urls = FIFinderSyncController.default().selectedItemURLs(), !urls.isEmpty else { return }
        let paste = NSPasteboard.general
        paste.clearContents()
        paste.setString(urls.map { $0.path }.joined(separator: "\n"), forType: .string)
    }

    @objc func openAppFromMenu(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? ExternalApp else { return }
        guard let dir = currentDirectory() else { return }
        FileActions.openApp(bundleID: app.bundleID, at: dir)
    }

    @objc func openDirFromMenu(_ sender: NSMenuItem) {
        guard let dir = sender.representedObject as? QuickDir else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dir.path)
    }

    @objc func openSettingsFromMenu(_ sender: NSMenuItem) {
        FileActions.openHostApp()
    }

    // MARK: - 核心逻辑

    /// 在 directory 下创建文件：文件名自动递增避免覆盖；可用模板。
    static func createFile(in directory: URL, format: FileFormat, templateBookmark: Data?, base: String) {
        let raw = format.ext.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let ext = raw.hasPrefix(".") ? String(raw.dropFirst()) : raw
        let fullExt = ext.isEmpty ? "" : ".\(ext)"

        var candidate = directory.appendingPathComponent("\(base)\(fullExt)")
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(base) \(counter)\(fullExt)")
            counter += 1
        }

        var data: Data = format.content.data(using: .utf8) ?? Data()
        if format.useTemplate, let bm = templateBookmark,
           let tmpl = templateData(for: ext, bookmark: bm) {
            data = tmpl
        }

        do {
            try data.write(to: candidate)
        } catch {
            NSLog("QuickRight: 创建文件失败 \(error.localizedDescription)")
        }
    }

    /// 用 NSWorkspace 以指定 App 打开目录；找不到 Bundle ID 时退回 `open -b`。
    static func openApp(bundleID: String, at directory: URL) {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let cfg = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([directory], withApplicationAt: appURL, configuration: cfg) { _, error in
                if let error {
                    NSLog("QuickRight: 打开应用失败 \(error.localizedDescription)")
                }
            }
        } else {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            proc.arguments = ["-b", bundleID, directory.path]
            try? proc.run()
        }
    }

    /// 唤起主程序设置窗口：先按 Bundle ID 打开，再发通知（若已在运行则提到前台）。
    static func openHostApp() {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: AppInfo.hostBundleID) {
            NSWorkspace.shared.open(appURL)
        }
        DistributedNotificationCenter.default().postNotificationName(
            .openSettings, object: nil, userInfo: nil, deliverImmediately: true
        )
    }

    /// 通过安全范围书签读取模板文件夹中的 template.<ext> 内容。
    static func templateData(for ext: String, bookmark: Data) -> Data? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        let candidate = url.appendingPathComponent("template.\(ext)")
        return try? Data(contentsOf: candidate)
    }
}
