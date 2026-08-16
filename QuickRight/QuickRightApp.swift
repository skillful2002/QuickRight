import SwiftUI

/// 应用入口（SwiftUI App 生命周期）：由 SwiftUI 自己创建并管理设置窗口，
/// 避免之前 AppKit 手动管理 NSHostingController/NSWindow 时窗口被压成 0 的坑。
@main
struct QuickRightApp: App {
    /// 注入 AppDelegate，仅用于：首次启动落盘默认配置 + 监听扩展发来的「打开设置」通知。
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = ConfigStore()

    var body: some Scene {
        WindowGroup("右键快捷 - 设置") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 540, minHeight: 440)
        }
        .windowResizability(.contentSize)
    }
}