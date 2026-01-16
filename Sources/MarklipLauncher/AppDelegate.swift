import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_: Notification) {
        // Initialize dependencies
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
