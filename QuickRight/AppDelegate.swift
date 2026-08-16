import Cocoa
import SwiftUI

/// 主程序入口：标准窗口 App，不常驻菜单栏。
/// 双击运行即弹出设置窗口；扩展点击右键菜单「设置」时会发来通知，这里重新唤出窗口。
@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let store = ConfigStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("QuickRight: applicationDidFinishLaunching 开始执行")
        // 首次启动：若配置文件尚不存在，写入默认配置，保证主程序与扩展读到一致内容。
        if ConfigIO.load() == nil {
            ConfigIO.save(store.config)
            NSLog("QuickRight: 已写入默认配置文件")
        }
        showSettings()

        // 扩展在用户点击右键「设置」时发送此通知，确保即使本程序已在运行也能把窗口提到前台。
        DistributedNotificationCenter.default().addObserver(
            forName: .openSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.showSettings()
            }
        }
    }

    private func showSettings() {
        NSLog("QuickRight: showSettings 进入, window 是否已存在=\(window != nil)")
        if window == nil {
            let root = ContentView().environmentObject(store)
            let controller = NSHostingController(rootView: root)
            // 关键：macOS 13+ NSHostingController 默认会按 SwiftUI 内容的固有尺寸
            // 自动调整窗口大小；而 TabView 的固有尺寸在 AppKit 中可能解析为 0，
            // 导致窗口实际存在但宽高为 0，用户只能看到 Dock 图标。显式关闭
            // sizingOptions 并指定固定 contentRect，确保窗口一定可见。
            if #available(macOS 13.0, *) {
                controller.sizingOptions = []
            }
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 440),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            win.contentViewController = controller
            win.title = "右键快捷 - 设置"
            win.isReleasedWhenClosed = false
            win.contentMinSize = NSSize(width: 540, height: 440)
            win.center()
            window = win
            NSLog("QuickRight: 设置窗口已创建")
        }
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        NSLog("QuickRight: 已调用 makeKeyAndOrderFront + orderFrontRegardless + activate")
    }

    /// 关闭最后一个窗口即退出（工具类 App 行为）。
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    /// 点击 Dock 图标时若窗口已关，重新唤出（否则关掉窗口后点 Dock 无反应）。
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }
}
