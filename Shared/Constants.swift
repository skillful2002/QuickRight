import Foundation

/// 全局常量：App Group、主程序 Bundle ID、跨进程通知名。
/// 主程序与 Finder Sync 扩展都依赖这些值，必须保持一致。
struct AppInfo {
    /// App Group 标识（主程序与扩展都要开启相同的 App Group 能力）
    static let appGroupID = "group.com.quickright.QuickRight"
    /// 主程序 Bundle ID，扩展用它来唤起设置界面
    static let hostBundleID = "com.quickright.QuickRight"
    /// 扩展 → 主程序：请求打开设置窗口的通知名
    static let openSettingsNotification = "com.quickright.QuickRight.openSettings"
}

extension Notification.Name {
    static let openSettings = Notification.Name(AppInfo.openSettingsNotification)
}
