import Cocoa
import SwiftUI

/// AppDelegate 仅承担 SwiftUI 生命周期不便处理的两件事：
/// 1. 首次启动时把默认配置落盘（保证主程序与扩展配置一致）；
/// 2. 监听扩展发来的「打开设置」分布式通知，把窗口拉到前台。
/// 窗口的创建与显示由 `QuickRightApp`（SwiftUI App 生命周期）负责。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("QuickRight: AppDelegate.applicationDidFinishLaunching")
        // 首次启动：若配置文件尚不存在，写入默认配置。
        if ConfigIO.load() == nil {
            ConfigIO.save(MenuConfig.default)
            NSLog("QuickRight: 已写入默认配置")
        }

        // 扩展点击右键「设置」时会发送此通知，确保即使本程序已在运行也能把窗口提到前台。
        DistributedNotificationCenter.default().addObserver(
            forName: .openSettings,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                Self.bringSettingsWindowToFront()
            }
        }
    }

    /// 关闭最后一个窗口即退出（工具类 App 行为）。
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    /// 点击 Dock 图标时若窗口已关，重新唤出。
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Self.bringSettingsWindowToFront()
        return true
    }

    /// 找到 SwiftUI 创建的设置窗口并强制显示到最前。
    private static func bringSettingsWindowToFront() {
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}