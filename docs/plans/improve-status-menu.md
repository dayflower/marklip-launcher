# Implementation Plan: Improve Status Bar Menu

## Overview

Enhance the marklip-launcher status bar menu to dynamically enable/disable menu items based on clipboard content and add version information display.

## Requirements

### Menu Item Enablement Logic

1. **Auto**: Disabled when clipboard has no HTML format AND (no text format OR empty text)
2. **Convert to HTML**: Disabled when clipboard has no text format OR empty text
3. **Convert to markdown**: Disabled when clipboard has no HTML format
4. **Startup Item Configuration**: Always enabled (no change)

### Menu Improvements

1. Add version header at the top (e.g., "marklip 1.0.0") - always disabled (display only)
2. Change "Quit" menu title to "Quit marklip"

## Technical Analysis

### Current State

- Menu is built once in `StatusBarController.setupStatusBar()` during initialization
- All menu items are currently always enabled
- No clipboard access functionality exists in the launcher
- Version is defined in Info.plist (currently "1.0.0")
- Menu uses standard NSMenu/NSMenuItem pattern

### Key Challenges

1. **Dynamic menu state**: Need to check clipboard on each menu open
2. **Clipboard access**: Must access NSPasteboard to check for HTML and text content
3. **Version retrieval**: Read from Bundle.main.infoDictionary at runtime
4. **Menu delegation**: Use NSMenuDelegate to update menu items before display

## Implementation Design

### Architecture Changes

```
StatusBarController
  ├─ Add NSMenuDelegate conformance
  ├─ Implement menuWillOpen(_:) to update item states
  ├─ Add clipboard checking helper methods
  └─ Add version retrieval helper method
```

### Critical Files to Modify

- [Sources/MarklipLauncher/StatusBarController.swift](Sources/MarklipLauncher/StatusBarController.swift) - Main implementation

### Implementation Steps

#### Step 1: Add Menu Item References

Store references to menu items that need dynamic enable/disable:

```swift
class StatusBarController {
    private var statusItem: NSStatusItem!
    private let marklipExecutor: MarklipExecutor
    private let launchAgentManager: LaunchAgentManager

    // Add menu item references
    private var autoItem: NSMenuItem!
    private var toHTMLItem: NSMenuItem!
    private var toMarkdownItem: NSMenuItem!

    // ...
}
```

#### Step 2: Add Version Header Menu Item

In `setupStatusBar()`, add version header as first menu item:

```swift
let menu = NSMenu()

// Version header (disabled, display-only)
let version = getAppVersion()
let versionItem = NSMenuItem(title: "marklip \(version)", action: nil, keyEquivalent: "")
versionItem.isEnabled = false
menu.addItem(versionItem)

menu.addItem(NSMenuItem.separator())

// Existing command items...
```

#### Step 3: Implement Version Retrieval

Add helper method to read version from Bundle:

```swift
private func getAppVersion() -> String {
    guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
        return "unknown"
    }
    return version
}
```

#### Step 4: Update Quit Menu Title

Change from "Quit" to "Quit marklip":

```swift
let quitItem = NSMenuItem(title: "Quit marklip", action: #selector(quit), keyEquivalent: "q")
```

#### Step 5: Add NSMenuDelegate Conformance

Conform to NSMenuDelegate and set delegate:

```swift
class StatusBarController: NSMenuDelegate {
    // ...

    private func setupStatusBar() {
        // ...
        let menu = NSMenu()
        menu.delegate = self  // Set delegate
        // ...
    }

    // Implement delegate method
    func menuWillOpen(_ menu: NSMenu) {
        updateMenuItemStates()
    }
}
```

#### Step 6: Implement Clipboard Checking Methods

Add helpers to check clipboard content:

```swift
private func hasHTMLInClipboard() -> Bool {
    let pasteboard = NSPasteboard.general
    return pasteboard.availableType(from: [.html]) != nil
}

private func hasTextInClipboard() -> Bool {
    let pasteboard = NSPasteboard.general
    guard let text = pasteboard.string(forType: .string) else {
        return false
    }
    // Note: Whitespace-only text is considered valid content
    return !text.isEmpty
}
```

#### Step 7: Implement Menu State Update Logic

Add method to update menu item enabled states based on clipboard:

```swift
private func updateMenuItemStates() {
    let hasHTML = hasHTMLInClipboard()
    let hasText = hasTextInClipboard()

    // Auto: disabled when no HTML AND no text
    autoItem.isEnabled = hasHTML || hasText

    // Convert to HTML: disabled when no text
    toHTMLItem.isEnabled = hasText

    // Convert to markdown: disabled when no HTML
    toMarkdownItem.isEnabled = hasHTML
}
```

#### Step 8: Store Menu Item References

Update `setupStatusBar()` to store references:

```swift
// marklip commands
autoItem = NSMenuItem(title: "Auto", action: #selector(runAuto), keyEquivalent: "a")
autoItem.target = self
menu.addItem(autoItem)

toHTMLItem = NSMenuItem(title: "Convert to HTML", action: #selector(runToHTML), keyEquivalent: "h")
toHTMLItem.target = self
menu.addItem(toHTMLItem)

toMarkdownItem = NSMenuItem(title: "Convert to markdown", action: #selector(runToMarkdown), keyEquivalent: "m")
toMarkdownItem.target = self
menu.addItem(toMarkdownItem)
```

## Implementation Order

1. Add menu item reference properties
2. Store references in setupStatusBar()
3. Add version header menu item
4. Update Quit menu title
5. Add version retrieval helper
6. Add NSMenuDelegate conformance
7. Implement clipboard checking helpers
8. Implement menu state update logic
9. Set menu delegate in setupStatusBar()

## Testing & Verification

### Manual Testing Scenarios

1. **Empty clipboard**: All conversion items should be disabled
2. **Plain text only**: Auto and Convert to HTML should be enabled, Convert to markdown disabled
3. **HTML only**: Auto and Convert to markdown should be enabled, Convert to HTML disabled
4. **Both HTML and text**: All conversion items should be enabled
5. **Whitespace-only text**: Should be treated as valid content (Auto and Convert to HTML enabled)
6. **Version display**: Verify "marklip 1.0.0" appears at top of menu (disabled)
7. **Quit menu**: Verify displays as "Quit marklip"

### Test Procedure

1. Build and run the application:
   ```bash
   make debug
   ```

2. Test each clipboard state:
   - Clear clipboard completely
   - Copy plain text from a text editor
   - Copy HTML from a web browser
   - Copy whitespace-only text

3. For each state:
   - Click the status bar icon
   - Verify correct menu items are enabled/disabled
   - Verify version header displays correctly
   - Verify Quit menu shows "Quit marklip"

4. Functional verification:
   - Ensure enabled menu items still execute correctly
   - Ensure disabled items don't execute (grayed out)

## Notes

- Uses NSPasteboard.general for clipboard access
- NSPasteboard.PasteboardType.html for HTML detection
- NSPasteboard.PasteboardType.string for text detection
- Whitespace-only strings are treated as valid content (per user preference)
- Menu state updates happen on menuWillOpen(_:) delegate callback
- Version is read once from Bundle.main.infoDictionary at menu creation time
- No external dependencies required (uses AppKit APIs only)
- Display name in version header: "marklip" (not "marklip-launcher")
