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
        if window == nil {
            let root = ContentView().environmentObject(store)
            let controller = NSHostingController(rootView: root)
            // 让窗口按 SwiftUI 内容的固有尺寸自动撑开，否则内容尺寸为 0 导致窗口不可见。
            if #available(macOS 13.0, *) {
                controller.sizingOptions = [.intrinsicContentSize]
            }
            let win = NSWindow(contentViewController: controller)
            win.title = "右键快捷 - 设置"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.setContentSize(NSSize(width: 540, height: 440))
            win.contentMinSize = NSSize(width: 540, height: 440)
            win.center()
            window = win
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// 关闭最后一个窗口即退出（工具类 App 行为）。
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
