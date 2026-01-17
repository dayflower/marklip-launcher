import Foundation

/// Executes marklip commands.
/// Note: The marklip command is invoked with --notify flag and handles
/// its own success/failure notifications. This executor only notifies
/// when the command is not found or execution fails at the process level.
class MarklipExecutor {
    private let notificationManager: NotificationManager

    // Cache marklip path (lazy evaluation)
    private var cachedMarklipPath: String?
    private var pathLookupAttempted = false

    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
    }

    /// Find the marklip command path (cached after first lookup)
    func findMarklipPath() -> String? {
        // Return cached result if already attempted
        if pathLookupAttempted {
            return cachedMarklipPath
        }

        pathLookupAttempted = true

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [Constants.marklipCommand]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                return nil
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            cachedMarklipPath = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return cachedMarklipPath
        } catch {
            return nil
        }
    }

    /// Execute a marklip command (marklip handles clipboard I/O directly)
    func executeCommand(_ subcommand: String) {
        // Verify marklip exists
        guard findMarklipPath() != nil else {
            notificationManager.showError("marklip command not found. Please install via Homebrew.")
            return
        }

        // Execute marklip command (marklip handles clipboard I/O directly)
        // Note: The --notify flag tells marklip to send its own notifications
        // for success/failure. This executor only notifies on command-not-found
        // or process-level execution failures.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [Constants.marklipCommand, "--notify", subcommand]

        do {
            try process.run()
            process.waitUntilExit()
            // marklip handles all conversion notifications via --notify flag
        } catch {
            // Only notify on process-level failures (e.g., executable not found, permission denied)
            notificationManager.showError("Failed to execute marklip: \(error.localizedDescription)")
        }
    }

    /// Invalidate cached path (useful for testing or when marklip installation changes)
    func invalidatePathCache() {
        cachedMarklipPath = nil
        pathLookupAttempted = false
    }
}
