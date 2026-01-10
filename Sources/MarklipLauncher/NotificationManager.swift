import Foundation

/// NotificationManager provides system notifications using the legacy NSUserNotification API.
///
/// ARCHITECTURAL DECISION:
/// This class intentionally uses NSUserNotification (deprecated since macOS 11.0)
/// instead of the modern UserNotifications framework.
///
/// RATIONALE:
/// The UserNotifications framework requires the application to be distributed as a .app bundle
/// with proper code signing and entitlements. This application runs as a standalone CLI executable
/// (without an app bundle) and does not require code signing. Using NSUserNotification allows
/// the application to display notifications without these requirements.
///
/// MAINTENANCE NOTE:
/// Future macOS versions may completely remove NSUserNotification support. At that point,
/// either the application architecture must be changed to use a .app bundle, or an alternative
/// notification mechanism must be implemented.
@available(macOS, deprecated: 11.0, message: "Use UserNotifications framework instead; we intentionally use NSUserNotification to avoid code signing requirements for CLI executable")
class NotificationManager {
    /// Show a success notification
    func showSuccess(_ message: String) {
        let notification = NSUserNotification()
        notification.title = Constants.applicationName
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
    }

    /// Show an error notification
    func showError(_ message: String) {
        let notification = NSUserNotification()
        notification.title = "\(Constants.applicationName) Error"
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
    }
}
