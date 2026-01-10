# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

marklip-launcher is a macOS status bar application written in Swift that provides a GUI interface for the [marklip](https://github.com/dayflower/marklip) command-line tool. It enables clipboard-based Markdown/HTML conversion through a system tray icon.

**Key characteristics:**
- Standalone CLI executable (not an App bundle)
- Uses Swift Package Manager (no Xcode required)
- macOS 12.0+ required
- Built with deprecated `NSUserNotification` APIs (works without code signing)
- Depends on external `marklip` command (installed via Homebrew)

## Build Commands

```bash
# Build release version
make build
# or: swift build -c release

# Build and run debug version
make debug
# or: swift build && .build/debug/marklip-launcher

# Install to /usr/local/bin
make install

# Uninstall
make uninstall

# Clean build artifacts
make clean
# or: swift package clean
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
- **NotificationManager**: Wrapper around deprecated NSUserNotification APIs
- **Constants**: Application-wide constants (bundle ID, app name, command name)

### Info.plist Embedding

The application uses linker flags to embed Info.plist directly into the executable binary (see [Package.swift:19-25](Package.swift#L19-L25)). This allows `LSUIElement` to work in a CLI executable format without requiring an App bundle structure.

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
2. Uses the absolute path from `ProcessInfo.processInfo.arguments.first`
3. Loads via `launchctl load`

**Critical**: If the executable is moved after registration, the LaunchAgent will fail. Users must unregister and re-register.

## Technical Constraints

- **No Xcode**: Project uses Swift Package Manager exclusively
- **Deprecated APIs**: Uses `NSUserNotification` (deprecated since macOS 11) instead of UserNotifications framework to avoid code signing requirements
- **CLI executable format**: Not a .app bundle, runs as a standalone binary
- **Process-based IPC**: All marklip interaction via Process spawning (no library integration)

## Deprecation Warning Suppression

The application uses `NSUserNotification` (deprecated since macOS 11.0) and intentionally suppresses its deprecation warnings. This is necessary because:

1. The application runs as a CLI executable without an .app bundle
2. UserNotifications framework requires code signing and entitlements
3. NSUserNotification allows notifications without these requirements

Deprecation warnings are suppressed using `@available` attributes at:
- NotificationManager class definition
- Usage points in AppDelegate, MarklipExecutor, LaunchAgentManager

This design is intentional and documented to guide future maintainers. If future macOS versions remove NSUserNotification entirely, the application architecture will need to be reconsidered (either migrate to .app bundle + code signing, or use alternative notification mechanisms).
