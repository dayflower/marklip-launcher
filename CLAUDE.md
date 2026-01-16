# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

marklip-launcher is a macOS status bar application written in Swift that provides a GUI interface for the [marklip](https://github.com/dayflower/marklip) command-line tool. It enables clipboard-based Markdown/HTML conversion through a system tray icon.

**Key characteristics:**
- macOS App Bundle format (`.app`)
- Uses Swift Package Manager (no Xcode required)
- macOS 13.0+ required
- Uses modern `UserNotifications` framework
- Ad-hoc code signing (no Developer ID required)
- Depends on external `marklip` command (installed via Homebrew)

## Build Commands

```bash
# Build release App Bundle (with ad-hoc signing)
make build
# Creates: .build/release/marklip-launcher.app

# Install to ~/Applications
make install

# Run the app
make run
# or: open .build/release/marklip-launcher.app

# Build and run debug version
make debug

# Uninstall from ~/Applications
make uninstall

# Clean build artifacts
make clean
```

## Architecture

### Dependency Flow

The application follows a clean dependency injection pattern:

```
main.swift
  └─> AppDelegate
       └─> StatusBarController (UI)
            ├─> MarklipExecutor (Command execution)
            │    └─> NotificationManager
            └─> LaunchAgentManager (Startup configuration)
                 └─> NotificationManager
```

### Core Components

- **main.swift**: Entry point, creates NSApplication with `.accessory` activation policy (prevents Dock icon)
- **AppDelegate**: Application lifecycle management, initializes all managers and controllers
- **StatusBarController**: Builds status bar menu and handles user interactions
- **MarklipExecutor**: Executes marklip commands via Process and reports results via notifications
- **LaunchAgentManager**: Creates/removes LaunchAgent plist files in `~/Library/LaunchAgents/`
- **NotificationManager**: Uses modern UserNotifications framework with permission handling
- **Constants**: Application-wide constants (bundle ID, app name, command name)

### App Bundle Structure

The application is built as a standard macOS App Bundle:

```
marklip-launcher.app/
└── Contents/
    ├── MacOS/
    │   └── marklip-launcher      (executable)
    ├── Resources/                 (for future assets)
    └── Info.plist                 (bundle metadata)
```

The build process uses `Scripts/bundle-app.sh` to package the Swift-built executable into this structure, followed by ad-hoc code signing.

## External Dependencies

The application shells out to the `marklip` command, which must be installed separately:

```bash
brew install dayflower/tap/marklip
```

**Important**: `MarklipExecutor.findMarklipPath()` uses `/usr/bin/which` to locate the command. If marklip is not found, user operations will fail with an error notification.

## marklip Command Integration

The three menu actions correspond to marklip subcommands:
- "Auto" → `marklip auto` (auto-detect format)
- "Convert to HTML" → `marklip to-html`
- "Convert to markdown" → `marklip to-md`

All commands follow the same pattern:
1. Verify marklip command is available
2. Execute marklip via Process (marklip handles clipboard I/O directly)
3. Check exit status and show success/error notification

**Important**: The launcher does NOT pipe data through stdin/stdout. Instead, marklip commands directly access the system clipboard using macOS pasteboard APIs. The launcher's responsibility is limited to:
- Command execution
- Error detection (via exit status and stderr)
- User notification

## LaunchAgent Registration

When registering as a startup item, the application:
1. Creates `~/Library/LaunchAgents/com.example.dayflower.marklipLauncher.plist`
2. Uses the absolute path from `ProcessInfo.processInfo.arguments.first` (e.g., `~/Applications/marklip-launcher.app/Contents/MacOS/marklip-launcher`)
3. Loads via `launchctl load`

**Note**: For App Bundles, the path points to the executable inside the bundle. Moving the entire `.app` bundle requires unregistering and re-registering.

## Technical Constraints

- **No Xcode**: Project uses Swift Package Manager exclusively
- **App Bundle format**: Standard macOS `.app` bundle structure
- **Modern APIs**: Uses `UserNotifications` framework (requires macOS 13.0+)
- **Ad-hoc signing**: No Developer ID required for personal use
- **Process-based IPC**: All marklip interaction via Process spawning (no library integration)

## Notification Permissions

The application uses the UserNotifications framework, which requires user permission:

1. On first launch, the system prompts for notification permission
2. If permission is denied, notifications fail silently but the app continues to function
3. Users can re-enable permissions in System Settings > Notifications
4. No special entitlements are required for local notifications

The NotificationManager implements `UNUserNotificationCenterDelegate` to handle foreground notifications (important for status bar apps that are always "active").
