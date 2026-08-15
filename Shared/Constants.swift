import Foundation

/// 全局常量：主程序 Bundle ID、跨进程通知名。
/// 主程序与 Finder Sync 扩展都依赖这些值，必须保持一致。
/// 注意：本工程使用「固定路径共享配置」，不再依赖 App Group，
/// 因此可兼容免费 Apple ID 签名（App Group 需付费 Developer Program）。
struct AppInfo {
    /// 共享配置所在目录名（位于 ~/Library/Application Support/ 下）
    static let configSubfolder = "QuickRight"
    /// 主程序 Bundle ID，扩展用它来唤起设置界面
    static let hostBundleID = "com.quickright.QuickRight"
    /// 扩展 → 主程序：请求打开设置窗口的通知名
    static let openSettingsNotification = "com.quickright.QuickRight.openSettings"
}

extension Notification.Name {
    static let openSettings = Notification.Name(AppInfo.openSettingsNotification)
}
