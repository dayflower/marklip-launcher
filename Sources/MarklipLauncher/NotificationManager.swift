import Foundation
import UserNotifications

/// NotificationManager provides system notifications using the modern UserNotifications framework.
///
/// ARCHITECTURAL DECISION:
/// This class uses the UserNotifications framework introduced in macOS 10.14.
/// The application is now distributed as a .app bundle, allowing use of modern notification APIs.
///
/// PERMISSION HANDLING:
/// The first time a notification is shown, the system prompts for user permission.
/// If permission is denied, notifications will fail silently but the application will continue to function.
///
/// REQUIREMENTS:
/// - Application must be packaged as .app bundle
/// - No special entitlements required for local notifications
/// - Ad-hoc code signing is sufficient for personal use
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private var permissionGranted = false

    override init() {
        super.init()
        center.delegate = self
        requestPermission()
    }

    /// Request notification permission (asynchronous)
    private func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            self.permissionGranted = granted
        }
    }

    /// Show a success notification
    func showSuccess(_ message: String) {
        showNotification(title: Constants.applicationName, body: message)
    }

    /// Show an error notification
    func showError(_ message: String) {
        showNotification(title: "\(Constants.applicationName) Error", body: message)
    }

    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Show immediately
        )

        center.add(request) { error in
            if let error = error {
                print("Notification delivery error: \(error)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is active (status bar app is always "active")
        completionHandler([.banner, .sound])
    }
}
