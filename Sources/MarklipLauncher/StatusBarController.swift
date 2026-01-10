import AppKit

/// Manages the status bar menu and user interactions
@available(macOS, deprecated: 11.0)
class StatusBarController {
    private var statusItem: NSStatusItem!
    // Uses deprecated classes (see NotificationManager.swift for rationale)
    private let marklipExecutor: MarklipExecutor
    private let launchAgentManager: LaunchAgentManager

    init(marklipExecutor: MarklipExecutor, launchAgentManager: LaunchAgentManager) {
        self.marklipExecutor = marklipExecutor
        self.launchAgentManager = launchAgentManager
        setupStatusBar()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Marklip Launcher")
        }

        let menu = NSMenu()

        // marklip commands
        let autoItem = NSMenuItem(title: "Auto", action: #selector(runAuto), keyEquivalent: "a")
        autoItem.target = self
        menu.addItem(autoItem)

        let toHTMLItem = NSMenuItem(title: "Convert to HTML", action: #selector(runToHTML), keyEquivalent: "h")
        toHTMLItem.target = self
        menu.addItem(toHTMLItem)

        let toMarkdownItem = NSMenuItem(title: "Convert to markdown", action: #selector(runToMarkdown), keyEquivalent: "m")
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
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
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
}
