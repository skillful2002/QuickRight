import Foundation

/// App Group 容器内的配置文件读写，主程序和扩展共用。
enum ConfigIO {
    static let configFileName = "menuConfig.json"

    /// App Group 共享容器中的配置文件 URL；任一进程未开启 App Group 时返回 nil。
    static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppInfo.appGroupID)?
            .appendingPathComponent(configFileName)
    }

    /// 读取配置；文件不存在或解析失败时返回 nil（调用方应回退到默认值）。
    static func load() -> MenuConfig? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(MenuConfig.self, from: data)
    }

    /// 写入配置（原子写）。
    static func save(_ config: MenuConfig) {
        guard let url = fileURL else {
            NSLog("QuickRight: 无法定位 App Group 容器，配置未保存")
            return
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(config) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
