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
            // 注意：不要用 .intrinsicContentSize，它会让窗口按 SwiftUI 内容的“固有尺寸”
            // 收缩，而 TabView 的固有尺寸可能解析为 0，导致窗口不可见。
            // 这里直接以固定 540×440 显式建窗，内容用 .frame 填满即可稳定可见。
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 440),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            win.contentViewController = controller
            win.title = "右键快捷 - 设置"
            win.isReleasedWhenClosed = false
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
