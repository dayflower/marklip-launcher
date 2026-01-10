import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    @available(macOS, deprecated: 11.0)
    var statusBarController: StatusBarController?

    @available(macOS, deprecated: 11.0)
    func applicationDidFinishLaunching(_: Notification) {
        // Initialize dependencies
        // Note: NotificationManager uses deprecated NSUserNotification API intentionally
        // to avoid code signing requirements for CLI executable format.
        // See NotificationManager.swift for details.
        let notificationManager = NotificationManager()
        let marklipExecutor = MarklipExecutor(notificationManager: notificationManager)
        let launchAgentManager = LaunchAgentManager(notificationManager: notificationManager)

        // Initialize status bar controller
        statusBarController = StatusBarController(
            marklipExecutor: marklipExecutor,
            launchAgentManager: launchAgentManager,
        )
    }

    func applicationWillTerminate(_: Notification) {
        // Cleanup if needed
    }
}
