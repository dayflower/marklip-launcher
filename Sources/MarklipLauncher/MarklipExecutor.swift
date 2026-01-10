import Foundation

/// Executes marklip commands and reports results via notifications
@available(macOS, deprecated: 11.0)
class MarklipExecutor {
    // Uses deprecated NotificationManager (see NotificationManager.swift for rationale)
    private let notificationManager: NotificationManager

    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
    }

    /// Find the marklip command path
    func findMarklipPath() -> String? {
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
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [Constants.marklipCommand, "--notify", subcommand]

        // Capture stderr for error reporting
        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                // Success - marklip has already modified the clipboard
                notificationManager.showSuccess("Conversion completed successfully")
            } else {
                // Error - read stderr and show notification
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
                notificationManager.showError("marklip failed: \(errorMessage)")
            }
        } catch {
            notificationManager.showError("Failed to execute marklip: \(error.localizedDescription)")
        }
    }
}
