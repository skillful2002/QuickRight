import Foundation

/// 一种可在右键「新建文件」中创建的文件格式。
struct FileFormat: Codable, Identifiable, Hashable {
    var id: UUID
    /// 菜单中显示的名称，如「Markdown」
    var name: String
    /// 扩展名（不含点），如 txt / md / docx
    var ext: String
    /// 不勾选「模板」时写入文件的默认内容
    var content: String
    /// 勾选后，新建时复制模板文件夹中 template.<ext> 的内容
    var useTemplate: Bool

    init(id: UUID = UUID(), name: String, ext: String, content: String = "", useTemplate: Bool = false) {
        self.id = id
        self.name = name
        self.ext = ext
        self.content = content
        self.useTemplate = useTemplate
    }
}

/// 一个可被「在以下应用打开」调用的外部 App（按 Bundle ID 调用）。
struct ExternalApp: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var bundleID: String

    init(id: UUID = UUID(), name: String, bundleID: String) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
    }
}

/// 一个右键「常用目录」中可快速在 Finder 打开的目录。
struct QuickDir: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var path: String

    init(id: UUID = UUID(), name: String, path: String) {
        self.id = id
        self.name = name
        self.path = path
    }
}

/// 整体配置，序列化为 App Group 容器中的 menuConfig.json，
/// 主程序写入、扩展在每次右键时读取（天然实时生效）。
struct MenuConfig: Codable {
    var formats: [FileFormat]
    var externalApps: [ExternalApp]
    var quickDirs: [QuickDir]
    /// 模板文件夹的安全范围书签（Data），沙盒下扩展用它读取模板
    var templateFolderBookmark: Data?
    /// 模板文件夹路径（仅用于界面展示）
    var templateFolderPath: String?
    /// 新建文件的默认文件名前缀，如 untitled
    var newFileNameBase: String

    static var `default`: MenuConfig {
        MenuConfig(
            formats: [
                FileFormat(name: "文本文件", ext: "txt"),
                FileFormat(name: "Markdown", ext: "md"),
                FileFormat(name: "JSON", ext: "json", content: "{\n  \n}"),
                FileFormat(name: "RTF", ext: "rtf"),
                FileFormat(name: "CSV", ext: "csv"),
                FileFormat(name: "空白 Word", ext: "docx"),
                FileFormat(name: "空白 Excel", ext: "xlsx"),
                FileFormat(name: "空白 PPT", ext: "pptx"),
                FileFormat(name: "Python", ext: "py"),
                FileFormat(name: "Shell", ext: "sh")
            ],
            externalApps: [
                ExternalApp(name: "终端", bundleID: "com.apple.Terminal"),
                ExternalApp(name: "iTerm2", bundleID: "com.googlecode.iterm2"),
                ExternalApp(name: "Visual Studio Code", bundleID: "com.microsoft.VSCode"),
                ExternalApp(name: "Sublime Text", bundleID: "com.sublimetext.4")
            ],
            quickDirs: [
                QuickDir(name: "桌面", path: NSHomeDirectory() + "/Desktop"),
                QuickDir(name: "下载", path: NSHomeDirectory() + "/Downloads"),
                QuickDir(name: "文档", path: NSHomeDirectory() + "/Documents")
            ],
            templateFolderBookmark: nil,
            templateFolderPath: nil,
            newFileNameBase: "untitled"
        )
    }
}
