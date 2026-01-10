import AppKit

/// Manages the status bar menu and user interactions
@available(macOS, deprecated: 11.0)
class StatusBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    // Uses deprecated classes (see NotificationManager.swift for rationale)
    private let marklipExecutor: MarklipExecutor
    private let launchAgentManager: LaunchAgentManager

    // Menu item references for dynamic enable/disable
    private var autoItem: NSMenuItem!
    private var toHTMLItem: NSMenuItem!
    private var toMarkdownItem: NSMenuItem!

    init(marklipExecutor: MarklipExecutor, launchAgentManager: LaunchAgentManager) {
        self.marklipExecutor = marklipExecutor
        self.launchAgentManager = launchAgentManager
        super.init()
        setupStatusBar()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Marklip Launcher")
        }

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        // Version header (disabled, display-only)
        let version = getAppVersion()
        let versionItem = NSMenuItem(title: "marklip \(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)

        menu.addItem(NSMenuItem.separator())

        // marklip commands
        autoItem = NSMenuItem(title: "Auto", action: #selector(runAuto), keyEquivalent: "a")
        autoItem.target = self
        menu.addItem(autoItem)

        toHTMLItem = NSMenuItem(title: "Convert to HTML", action: #selector(runToHTML), keyEquivalent: "h")
        toHTMLItem.target = self
        menu.addItem(toHTMLItem)

        toMarkdownItem = NSMenuItem(title: "Convert to markdown", action: #selector(runToMarkdown), keyEquivalent: "m")
        toMarkdownItem.target = self
        menu.addItem(toMarkdownItem)

        menu.addItem(NSMenuItem.separator())

        // Configuration submenu
        let configMenu = NSMenu()

        let registerItem = NSMenuItem(title: "Register as Startup Item", action: #selector(registerStartupItem), keyEquivalent: "")
        registerItem.target = self
        configMenu.addItem(registerItem)

        let unregisterItem = NSMenuItem(title: "Unregister as Startup Item", action: #selector(unregisterStartupItem), keyEquivalent: "")
        unregisterItem.target = self
        configMenu.addItem(unregisterItem)

        let configMenuItem = NSMenuItem(title: "Configuration", action: nil, keyEquivalent: "")
        configMenuItem.submenu = configMenu
        menu.addItem(configMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit marklip", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func runAuto() {
        marklipExecutor.executeCommand("auto")
    }

    @objc private func runToHTML() {
        marklipExecutor.executeCommand("to-html")
    }

    @objc private func runToMarkdown() {
        marklipExecutor.executeCommand("to-md")
    }

    @objc private func registerStartupItem() {
        launchAgentManager.register()
    }

    @objc private func unregisterStartupItem() {
        launchAgentManager.unregister()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateMenuItemStates()
    }

    // MARK: - Helper Methods

    private func getAppVersion() -> String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "unknown"
        }
        return version
    }

    private func hasHTMLInClipboard() -> Bool {
        let pasteboard = NSPasteboard.general
        return pasteboard.availableType(from: [.html]) != nil
    }

    private func hasTextInClipboard() -> Bool {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string) else {
            return false
        }
        // Note: Whitespace-only text is considered valid content
        return !text.isEmpty
    }

    private func updateMenuItemStates() {
        let hasHTML = hasHTMLInClipboard()
        let hasText = hasTextInClipboard()

        // Auto: disabled when no HTML AND no text
        autoItem.isEnabled = hasHTML || hasText

        // Convert to HTML: disabled when no text
        toHTMLItem.isEnabled = hasText

        // Convert to markdown: disabled when no HTML
        toMarkdownItem.isEnabled = hasHTML
    }
}
