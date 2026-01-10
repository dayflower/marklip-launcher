import Foundation

enum LaunchAgentError: Error {
    case executablePathNotFound
    case launchctlLoadFailed
    case launchctlUnloadFailed
    case notRegistered

    var localizedDescription: String {
        switch self {
        case .executablePathNotFound:
            "Could not determine executable path"
        case .launchctlLoadFailed:
            "Failed to load launch agent with launchctl"
        case .launchctlUnloadFailed:
            "Failed to unload launch agent with launchctl"
        case .notRegistered:
            "Launch agent is not registered"
        }
    }
}

/// Manages LaunchAgent registration for startup behavior
@available(macOS, deprecated: 11.0)
class LaunchAgentManager {
    // Uses deprecated NotificationManager (see NotificationManager.swift for rationale)
    private let notificationManager: NotificationManager
    private let bundleIdentifier = Constants.bundleIdentifier
    private let launchAgentsDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents")

    private var plistPath: URL {
        launchAgentsDir.appendingPathComponent("\(bundleIdentifier).plist")
    }

    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
    }

    /// Check if the launch agent is registered
    func isRegistered() -> Bool {
        FileManager.default.fileExists(atPath: plistPath.path)
    }

    /// Register as startup item
    func register() {
        do {
            try performRegistration()
            notificationManager.showSuccess("Successfully registered as startup item")
        } catch {
            notificationManager.showError("Registration failed: \(error.localizedDescription)")
        }
    }

    /// Unregister as startup item
    func unregister() {
        do {
            try performUnregistration()
            notificationManager.showSuccess("Successfully unregistered as startup item")
        } catch {
            notificationManager.showError("Unregistration failed: \(error.localizedDescription)")
        }
    }

    private func performRegistration() throws {
        // Get executable path
        guard let executablePath = ProcessInfo.processInfo.arguments.first else {
            throw LaunchAgentError.executablePathNotFound
        }

        // Create LaunchAgents directory if it doesn't exist
        try FileManager.default.createDirectory(
            at: launchAgentsDir,
            withIntermediateDirectories: true,
        )

        // Create plist content
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(bundleIdentifier)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
            <key>ProcessType</key>
            <string>Interactive</string>
        </dict>
        </plist>
        """

        // Write plist file
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)

        // Load with launchctl
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", plistPath.path]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            // Clean up plist file if load failed
            try? FileManager.default.removeItem(at: plistPath)
            throw LaunchAgentError.launchctlLoadFailed
        }
    }

    private func performUnregistration() throws {
        guard isRegistered() else {
            throw LaunchAgentError.notRegistered
        }

        // Unload with launchctl
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", plistPath.path]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw LaunchAgentError.launchctlUnloadFailed
        }

        // Delete plist file
        try FileManager.default.removeItem(at: plistPath)
    }
}
