# Implementation Plan: CLI Executable to App Bundle Migration

## Overview

This plan outlines the migration of marklip-launcher from a CLI executable format to a standard macOS App Bundle format, along with replacing the deprecated NSUserNotification API with the modern UserNotifications framework.

## Current Architecture

- **Format**: CLI executable (not an App Bundle)
- **Build**: Swift Package Manager only
- **Info.plist**: Embedded via linker flags in Package.swift
- **Notifications**: NSUserNotification (deprecated since macOS 11)
- **Dependencies**: External `marklip` command (Homebrew)
- **Installation**: `/usr/local/bin/marklip-launcher`

## Target Architecture

- **Format**: App Bundle (`.app`)
- **Build**: Swift Package Manager + shell scripts
- **Info.plist**: Standard location in `Contents/Info.plist`
- **Notifications**: UserNotifications framework
- **Dependencies**: External `marklip` command (unchanged)
- **Installation**: `~/Applications/marklip-launcher.app` (user-specific)
- **Code Signing**: Ad-hoc signing only (no Developer ID required)

## Implementation Phases

### Phase 1: App Bundle Structure and Build System

#### 1.1 Update Package.swift

**File**: [Package.swift](../../../Package.swift)

**Changes**:
- Remove linker settings that embed Info.plist (`-sectcreate` flags)
- Update minimum macOS version from `.v12` to `.v13` (for full UserNotifications support)
- Keep `.executable()` product type (post-processing will create .app bundle)
- Add resources declaration for Info.plist

**Before**:
```swift
.executableTarget(
    name: "MarklipLauncher",
    linkerSettings: [
        .unsafeFlags([
            "-sectcreate", "__TEXT", "__info_plist",
            "Sources/Resources/Info.plist"
        ])
    ]
)
```

**After**:
```swift
.executableTarget(
    name: "MarklipLauncher",
    dependencies: [],
    resources: [
        .process("Resources")
    ]
)
```

#### 1.2 Create App Bundle Build Script

**New File**: `Scripts/bundle-app.sh`

**Purpose**: Package the Swift-built executable into an App Bundle structure

**Script Tasks**:
1. Build release executable with `swift build -c release`
2. Create `.app/Contents/MacOS/` directory
3. Copy executable to `Contents/MacOS/marklip-launcher`
4. Create `.app/Contents/Resources/` directory
5. Copy Info.plist to `Contents/Info.plist`
6. Set appropriate permissions

**Structure Created**:
```
marklip-launcher.app/
└── Contents/
    ├── MacOS/
    │   └── marklip-launcher          (executable)
    ├── Resources/                     (for future assets)
    └── Info.plist                     (metadata)
```

#### 1.3 Update Makefile

**File**: [Makefile](../../../Makefile)

**Changes**:
- `build` target: Call `Scripts/bundle-app.sh` to create .app bundle
- `install` target: Copy .app to `~/Applications/` instead of binary to `/usr/local/bin/`
- `clean` target: Remove .app bundle directory
- Add `codesign` target for ad-hoc signing (automatically called after build)
- Add `uninstall` target to remove from `~/Applications/`

**New Targets**:
```makefile
build:
    ./Scripts/bundle-app.sh
    codesign --force --deep --sign - .build/release/marklip-launcher.app

install: build
    mkdir -p ~/Applications
    cp -R .build/release/marklip-launcher.app ~/Applications/

uninstall:
    rm -rf ~/Applications/marklip-launcher.app
```

#### 1.4 Update Info.plist

**File**: [Sources/Resources/Info.plist](../../../Sources/Resources/Info.plist)

**Add Required Keys**:
- `CFBundleExecutable`: `marklip-launcher`
- `CFBundlePackageType`: `APPL`
- `NSPrincipalClass`: `NSApplication`
- `CFBundleShortVersionString`: `0.1.0`
- `NSHumanReadableCopyright`: `Copyright © 2026`

**Keep Existing Keys**:
- `CFBundleIdentifier`: `com.example.dayflower.marklipLauncher`
- `LSUIElement`: `true` (status bar-only app)
- `NSHighResolutionCapable`: `true`

### Phase 2: UserNotifications Framework Migration

#### 2.1 Rewrite NotificationManager

**File**: [Sources/MarklipLauncher/NotificationManager.swift](../../../Sources/MarklipLauncher/NotificationManager.swift)

**Complete Rewrite**:
- Import `UserNotifications` instead of `AppKit`
- Implement `UNUserNotificationCenterDelegate`
- Add permission request in `init()`
- Replace `NSUserNotification` with `UNMutableNotificationContent`
- Replace `NSUserNotificationCenter` with `UNUserNotificationCenter`
- Use `UNNotificationRequest` for delivery
- Handle foreground notifications in delegate method

**Key Implementation Details**:
```swift
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        requestPermission()
    }

    private func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            // Handle permission result
        }
    }

    func showSuccess(_ message: String) { /* ... */ }
    func showError(_ message: String) { /* ... */ }
}
```

#### 2.2 Remove Deprecation Suppressions

**Files to Update**:
- [Sources/MarklipLauncher/AppDelegate.swift](../../../Sources/MarklipLauncher/AppDelegate.swift)
- [Sources/MarklipLauncher/MarklipExecutor.swift](../../../Sources/MarklipLauncher/MarklipExecutor.swift)
- [Sources/MarklipLauncher/LaunchAgentManager.swift](../../../Sources/MarklipLauncher/LaunchAgentManager.swift)
- [Sources/MarklipLauncher/StatusBarController.swift](../../../Sources/MarklipLauncher/StatusBarController.swift)

**Action**: Remove all `@available(macOS, deprecated: 11.0)` attributes

### Phase 3: LaunchAgent App Bundle Support

#### 3.1 Verify LaunchAgentManager

**File**: [Sources/MarklipLauncher/LaunchAgentManager.swift](../../../Sources/MarklipLauncher/LaunchAgentManager.swift)

**Analysis**: `ProcessInfo.processInfo.arguments.first` correctly returns the full executable path even in App Bundles:
- App Bundle: `/Applications/marklip-launcher.app/Contents/MacOS/marklip-launcher`
- CLI (legacy): `/usr/local/bin/marklip-launcher`

**Code Changes**: None required (existing code works)

**Documentation Update**: Add comment explaining App Bundle path handling:
```swift
/// Get executable path
/// For App Bundle: /Applications/marklip-launcher.app/Contents/MacOS/marklip-launcher
/// For CLI executable (legacy): /usr/local/bin/marklip-launcher
guard let executablePath = ProcessInfo.processInfo.arguments.first else {
    throw LaunchAgentError.executablePathNotFound
}
```

### Phase 4: Ad-hoc Code Signing

#### 4.1 Integrate Ad-hoc Signing into Build

**Purpose**: Automatically sign the app bundle with ad-hoc signature after build

**Implementation**: Add signing step directly in Makefile `build` target

**Command**:
```bash
codesign --force --deep --sign - .build/release/marklip-launcher.app
```

**Note**:
- Ad-hoc signing (`--sign -`) requires no certificates or Apple Developer Program membership
- Sufficient for personal use and installation to `~/Applications/`
- Does not allow distribution to other users (Gatekeeper will block)
- No entitlements file needed for local notifications

**Why Ad-hoc Only**:
Based on user preference, this implementation focuses on personal use without Developer ID requirements. Future distribution can be handled separately if needed.

### Phase 5: Documentation Updates

#### 5.1 Update CLAUDE.md

**File**: [CLAUDE.md](../../../CLAUDE.md)

**Changes**:
- Update "Standalone CLI executable" to "App Bundle format"
- Change "Uses deprecated `NSUserNotification` APIs" to "Uses UserNotifications framework"
- Update build commands to reflect .app bundle creation
- Change installation path from `/usr/local/bin/` to `~/Applications/`
- Update architecture diagram if needed
- Update "Technical Constraints" section
- Add note about ad-hoc code signing

#### 5.2 Update README.md (if exists)

**File**: [README.md](../../../README.md)

**Changes**:
- Update installation instructions (install to `~/Applications/`)
- Update build instructions (automatic ad-hoc signing)
- Document migration from CLI version
- Add LaunchAgent migration notes

## Critical Files

The following files are most critical for this migration:

1. **[Package.swift](../../../Package.swift)** - Remove linker flags, update platform version
2. **[Sources/MarklipLauncher/NotificationManager.swift](../../../Sources/MarklipLauncher/NotificationManager.swift)** - Complete rewrite for UserNotifications
3. **[Makefile](../../../Makefile)** - Update build flow for App Bundle with ad-hoc signing and `~/Applications/` install
4. **[Sources/Resources/Info.plist](../../../Sources/Resources/Info.plist)** - Add App Bundle required keys
5. **`Scripts/bundle-app.sh`** (new) - Core packaging script

## Implementation Order

**Recommended Sequential Order**:

1. Phase 1 (App Bundle Structure) - **Required First**
2. Phase 2 (UserNotifications) - **Requires Phase 1**
3. Phase 3 (LaunchAgent verification) - **Requires Phase 1**
4. Phase 4 (Ad-hoc Code Signing) - **Integrated into Phase 1, no separate step**
5. Phase 5 (Documentation) - **Final step**

**Alternative Incremental Approach**:
- Step 1: Phase 1 only (App Bundle with NSUserNotification) → Test
- Step 2: Phase 2 (Migrate to UserNotifications) → Test
- Step 3: Phase 4 (Add code signing) → Optional

## Risks and Mitigations

### Risk 1: Notification Permission Denied
**Impact**: No user feedback when permission is denied

**Mitigation**:
- App continues to function without notifications
- Consider showing alert dialog on first launch explaining notification usage
- Provide link to System Settings to re-enable notifications

### Risk 2: LaunchAgent Conflict
**Impact**: Both CLI and App Bundle versions might run simultaneously if old LaunchAgent exists

**Mitigation**:
- On first launch, detect and offer to remove old LaunchAgent entry
- Or change bundle identifier to allow coexistence

### Risk 3: marklip Command Not Found from App Bundle
**Impact**: App Bundle environment might not have proper PATH

**Mitigation**:
- Update `MarklipExecutor.findMarklipPath()` to explicitly check common locations:
  - `/usr/local/bin/marklip`
  - `/opt/homebrew/bin/marklip`
  - Use `/usr/bin/which` as fallback

### Risk 4: Gatekeeper Blocking Unsigned App
**Impact**: Unsigned .app distributed to other users will be blocked

**Mitigation**:
- Ad-hoc signing sufficient for personal use
- Developer ID signing required for distribution
- Document workaround: `xattr -cr marklip-launcher.app`

## Verification Plan

### Build Verification
1. Run `make clean && make build`
2. Verify `.build/release/marklip-launcher.app/` exists
3. Verify `Contents/MacOS/marklip-launcher` is executable
4. Verify `Contents/Info.plist` is present with all required keys
5. Run `open .build/release/marklip-launcher.app` - status bar icon should appear

### Notification Verification
1. First launch: notification permission dialog should appear
2. Grant permission
3. Test success notification: Register as Startup Item
4. Test error notification: Rename marklip command temporarily, try to convert

### LaunchAgent Verification
1. Register as Startup Item via menu
2. Verify `~/Library/LaunchAgents/com.example.dayflower.marklipLauncher.plist` created
3. Check `ProgramArguments` contains `.app/Contents/MacOS/marklip-launcher`
4. Log out and log back in
5. Verify app auto-starts and appears in status bar

### marklip Integration Verification
1. Copy Markdown text to clipboard
2. Select "Convert to HTML" from status bar menu
3. Verify clipboard contains HTML
4. Verify success notification appears

### Code Signing Verification
1. After build, run `codesign -dvvv .build/release/marklip-launcher.app`
2. Verify ad-hoc signature exists (Authority=-)
3. Run app to ensure it works with signature
4. After installing to `~/Applications/`, verify installed app is also signed

## Post-Migration Cleanup

After successful migration and testing:
1. Update minimum macOS version requirement in documentation
2. Consider removing backward compatibility code if any
3. Update GitHub repository README with new installation instructions
4. Consider creating DMG or Homebrew Cask for easier distribution

## Rollback Plan

If migration fails:
1. Revert Package.swift changes
2. Restore linker flags for Info.plist embedding
3. Revert NotificationManager to NSUserNotification
4. Restore @available deprecation suppressions
5. Build CLI executable: `swift build -c release`
6. Install to `/usr/local/bin/`: `make install`
