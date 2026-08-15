import Cocoa
import FinderSync

/// Finder Sync 扩展的 principal class。
/// 系统会在 Finder 启动时实例化它，并在用户右键时调用 menu(for:)。
final class FinderSync: FIFinderSync {

    override init() {
        super.init()
        // 监控用户主目录：桌面、下载、文档等都在其下，右键菜单即可出现。
        // 若需覆盖外接磁盘等更多位置，可在设置中引导用户开启「完全磁盘访问」并将此处改为监控 "/"。
        let home = URL(fileURLWithPath: NSHomeDirectory())
        FIFinderSyncController.default().directoryURLs = Set([home])
        // 诊断用：在「控制台」搜索 QuickRightFinder，可确认扩展是否已被系统加载。
        NSLog("QuickRightFinder: 扩展已初始化，监控目录 \(home.path)")
    }

    /// 每次右键都会调用，直接从 App Group 读取最新配置构建菜单（天然实时生效）。
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard let config = ConfigIO.load() else {
            return NSMenu(title: "右键快捷")
        }
        return MenuBuilder.buildMenu(config: config)
    }
}
