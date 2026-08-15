import Foundation

/// 固定路径配置读写（不依赖 App Group，兼容免费 Apple ID 签名）。
/// 主程序与 Finder Sync 扩展共用同一个目录：
///   ~/Library/Application Support/QuickRight/menuConfig.json
/// 两进程都关闭了 App Sandbox，因此可直接读写该固定路径。
enum ConfigIO {
    static let configFileName = "menuConfig.json"

    /// 共享配置目录（~/Library/Application Support/QuickRight），自动创建。
    static var configDirectory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent(AppInfo.configSubfolder, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// 配置文件 URL（固定路径，始终可用）。
    static var fileURL: URL {
        configDirectory.appendingPathComponent(configFileName)
    }

    /// 读取配置；文件不存在或解析失败时返回 nil（调用方应回退到默认值）。
    static func load() -> MenuConfig? {
        let url = fileURL
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(MenuConfig.self, from: data)
    }

    /// 写入配置（原子写）。
    static func save(_ config: MenuConfig) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(config) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
