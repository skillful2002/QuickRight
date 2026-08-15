import Foundation
import Combine

/// 配置状态容器（ObservableObject），供 SwiftUI 绑定。
/// 任何修改都会自动（防抖后）写入 App Group 容器，扩展读取即实时生效。
final class ConfigStore: ObservableObject {
    @Published var config: MenuConfig

    private var cancellable: AnyCancellable?

    init() {
        self.config = ConfigIO.load() ?? .default
        self.cancellable = $config
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] config in
                ConfigIO.save(config)
            }
    }
}
