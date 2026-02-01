import AppKit

final class StatusBarController: NSObject {
    private(set) var statusItem: NSStatusItem?
    private var toggleMenuItem: NSMenuItem?
    private var observerToken: Any?

    override init() {
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        // 加载状态栏图标：优先寻找专门的模板资源（AppIconTemplate），否则使用 AppIcon 并保留原色
        var statusImage: NSImage? = nil
        if let tmplURL = Bundle.main.url(forResource: "AppIconTemplate", withExtension: "pdf") {
            statusImage = NSImage(contentsOf: tmplURL)
        } else if let tmplURL = Bundle.main.url(
            forResource: "AppIconTemplate", withExtension: "svg")
        {
            statusImage = NSImage(contentsOf: tmplURL)
        }

        if statusImage == nil {
            // fallback to plain AppIcon (could be colored); do not force template mode
            if let svgURL = Bundle.main.url(forResource: "AppIcon", withExtension: "svg") {
                statusImage = NSImage(contentsOf: svgURL)
            }
            if statusImage == nil {
                statusImage = NSImage(named: "AppIcon")
            }
        }

        if let image = statusImage {
            // 如果资源名包含 Template，则让系统渲染为模板风格
            if Bundle.main.url(forResource: "AppIconTemplate", withExtension: "pdf") != nil
                || Bundle.main.url(forResource: "AppIconTemplate", withExtension: "svg") != nil
            {
                image.isTemplate = true
            } else {
                image.isTemplate = false
            }
            image.size = NSSize(width: 18, height: 18)
            button.image = image
        } else {
            button.title = "TakeARest"
        }

        // 允许按钮接收左右键事件，并在 action 中区分
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.action = #selector(statusBarButtonClicked(_:))
        button.target = self

        // 准备菜单并设置 targets
        let menu = NSMenu()
        let openItem = NSMenuItem(
            title: "打开主窗口", action: #selector(openMainWindow(_:)), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(NSMenuItem.separator())
        let toggleItem = NSMenuItem(
            title: "暂停", action: #selector(togglePause(_:)), keyEquivalent: "")
        toggleItem.target = self
        // 保存引用以便根据状态动态更新标题
        self.toggleMenuItem = toggleItem
        menu.addItem(toggleItem)
        let quitItem = NSMenuItem(
            title: "退出", action: #selector(terminateApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        // 将 menu 保存在 statusItem 的关联对象中（避免被释放）
        statusItem?.menu = nil  // 不直接绑定，否则左键会总是弹出菜单
        objc_setAssociatedObject(
            statusItem as Any, "statusMenu", menu, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // 监听 pause 状态变化以更新菜单文字
        observerToken = NotificationCenter.default.addObserver(
            forName: Notification.Name("TakeARest.PauseStateChanged"), object: nil, queue: .main
        ) { [weak self] note in
            guard let self = self else { return }
            if let info = note.userInfo, let paused = info["isPaused"] as? Bool {
                self.updateToggleTitle(isPaused: paused)
            } else {
                // 若未携带 userInfo，则尝试仅切换一次（保守做法）
                // 不做任何操作
            }
        }
    }

    deinit {
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    @objc private func statusBarButtonClicked(_ sender: Any?) {
        // 区分左右键
        guard let event = NSApp.currentEvent else {
            openMainWindow(nil)
            return
        }

        if event.type == .rightMouseUp {
            if let menu = objc_getAssociatedObject(statusItem as Any, "statusMenu") as? NSMenu {
                NSApp.activate(ignoringOtherApps: true)
                statusItem?.popUpMenu(menu)
            }
        } else {
            openMainWindow(nil)
        }
    }

    @objc private func openMainWindow(_ sender: Any?) {
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func togglePause(_ sender: Any?) {
        NotificationCenter.default.post(
            name: Notification.Name("TakeARest.TogglePause"), object: nil)
    }

    @MainActor private func updateToggleTitle(isPaused: Bool) {
        if let item = toggleMenuItem {
            item.title = isPaused ? "开始" : "暂停"
        }
    }

    @objc private func terminateApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}
