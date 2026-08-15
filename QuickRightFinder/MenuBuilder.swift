import Cocoa
import FinderSync

/// 根据 MenuConfig 构建 Finder 右键菜单。
enum MenuBuilder {

    static func buildMenu(config: MenuConfig) -> NSMenu {
        let menu = NSMenu(title: "右键快捷")

        // 1) 新建文件（子菜单，列出所有格式）
        let newSub = NSMenu()
        for fmt in config.formats {
            let item = NSMenuItem(
                title: fmt.name,
                action: #selector(FileActions.shared.createFileFromMenu(_:)),
                keyEquivalent: ""
            )
            item.representedObject = fmt
            item.target = FileActions.shared
            newSub.addItem(item)
        }
        let newItem = NSMenuItem(title: "新建文件", action: nil, keyEquivalent: "")
        newItem.submenu = newSub
        menu.addItem(newItem)

        // 2) 复制路径
        let copy = NSMenuItem(
            title: "复制路径",
            action: #selector(FileActions.shared.copyPathsFromMenu(_:)),
            keyEquivalent: ""
        )
        copy.target = FileActions.shared
        menu.addItem(copy)

        // 3) 在以下应用打开（子菜单）
        if !config.externalApps.isEmpty {
            let appSub = NSMenu()
            for app in config.externalApps {
                let it = NSMenuItem(
                    title: app.name,
                    action: #selector(FileActions.shared.openAppFromMenu(_:)),
                    keyEquivalent: ""
                )
                it.representedObject = app
                it.target = FileActions.shared
                appSub.addItem(it)
            }
            let appItem = NSMenuItem(title: "在以下应用打开", action: nil, keyEquivalent: "")
            appItem.submenu = appSub
            menu.addItem(appItem)
        }

        // 4) 常用目录（子菜单，在 Finder 打开）
        if !config.quickDirs.isEmpty {
            let dirSub = NSMenu()
            for d in config.quickDirs {
                let it = NSMenuItem(
                    title: d.name,
                    action: #selector(FileActions.shared.openDirFromMenu(_:)),
                    keyEquivalent: ""
                )
                it.representedObject = d
                it.target = FileActions.shared
                dirSub.addItem(it)
            }
            let dirItem = NSMenuItem(title: "常用目录", action: nil, keyEquivalent: "")
            dirItem.submenu = dirSub
            menu.addItem(dirItem)
        }

        menu.addItem(.separator())

        // 5) 设置（唤起主程序配置窗口）
        let settings = NSMenuItem(
            title: "设置",
            action: #selector(FileActions.shared.openSettingsFromMenu(_:)),
            keyEquivalent: ""
        )
        settings.target = FileActions.shared
        menu.addItem(settings)

        return menu
    }
}
