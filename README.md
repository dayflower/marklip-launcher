# Marklip Launcher

A macOS status bar application that integrates with the [marklip](https://github.com/dayflower/marklip) command-line tool for clipboard-based Markdown/HTML conversion.

## Features

- **Status Bar Integration**: Runs as a lightweight status bar application (no Dock icon)
- **Clipboard-based Conversion**: Convert content between Markdown and HTML using your clipboard
- **Auto-detection**: Automatically detect and convert between formats
- **Startup Item Support**: Register as a macOS LaunchAgent to start automatically at login
- **Native Notifications**: Get feedback on conversion success or errors via macOS Notification Center

## Prerequisites

- macOS 12.0 or later
- Swift 5.9 or later (Command Line Tools)
- [marklip](https://github.com/dayflower/marklip) installed via Homebrew

### Install marklip

```bash
brew install dayflower/tap/marklip
```

## Building

### Build from source

```bash
make build
```

This will create a release App Bundle at `.build/release/Marklip Launcher.app`.

### Debug build

```bash
make debug
```

## Installation

### Install to ~/Applications

```bash
make install
```

This will install the App Bundle to `~/Applications/Marklip Launcher.app`.

### Uninstall

```bash
make uninstall
```

## Usage

### Running the application

```bash
make run
```

Or if installed:

```bash
open ~/Applications/Marklip\ Launcher.app
```

Or directly run the executable:

```bash
~/Applications/Marklip\ Launcher.app/Contents/MacOS/marklip-launcher
```

The application will appear in your status bar with a 📋 icon.

### Menu Options

- **Auto**: Automatically detect format and convert (runs `marklip auto`)
- **Convert to HTML**: Convert Markdown from clipboard to HTML (runs `marklip to-html`)
- **Convert to markdown**: Convert HTML from clipboard to Markdown (runs `marklip to-md`)
- **Configuration**
  - **Register as Startup Item**: Create a LaunchAgent to start automatically at login
  - **Unregister as Startup Item**: Remove the LaunchAgent
- **Quit**: Exit the application

### Workflow

1. Copy text to your clipboard (Markdown or HTML)
2. Click the status bar icon
3. Select the desired conversion option
4. The converted content will replace your clipboard content
5. A notification will appear indicating success or any errors

## LaunchAgent Registration

To make Marklip Launcher start automatically when you log in:

1. Click the status bar icon
2. Select **Configuration → Register as Startup Item**
3. A notification will confirm successful registration

The application will now start automatically at login.

To unregister:

1. Click the status bar icon
2. Select **Configuration → Unregister as Startup Item**

**Note**: The LaunchAgent stores the absolute path to the App Bundle's executable. If you move the `.app` bundle after registration, you'll need to unregister and re-register.

## Migrating from marklip-launcher

If you previously installed `marklip-launcher.app` and registered it as a startup item, follow these steps to migrate to `Marklip Launcher.app`:

1. **Unregister the old LaunchAgent**:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.example.dayflower.marklipLauncher.plist
   rm ~/Library/LaunchAgents/com.example.dayflower.marklipLauncher.plist
   ```

2. **Remove the old app**:
   ```bash
   rm -rf ~/Applications/marklip-launcher.app
   ```

3. **Clean and install the new version**:
   ```bash
   make clean
   make install
   ```

4. **Launch and re-register**:
   ```bash
   open ~/Applications/Marklip\ Launcher.app
   # Then select: Configuration > Register as Startup Item
   ```

## Troubleshooting

### "marklip command not found" error

Make sure marklip is installed and in your PATH:

```bash
which marklip
```

If not found, install via Homebrew:

```bash
brew install dayflower/tap/marklip
```

### Clipboard is empty

Ensure you have copied text to your clipboard before selecting a conversion option.

### Notifications not appearing

The application uses `NSUserNotificationCenter`. Check your macOS notification settings:

1. Open **System Preferences → Notifications**
2. Ensure notifications are enabled for terminal or the application

### LaunchAgent not working

Verify the plist file exists:

```bash
ls ~/Library/LaunchAgents/com.example.dayflower.marklipLauncher.plist
```

Check if it's loaded:

```bash
launchctl list | grep marklipLauncher
```

Reload manually if needed:

```bash
launchctl load ~/Library/LaunchAgents/com.example.dayflower.marklipLauncher.plist
```

## License

See the [marklip](https://github.com/dayflower/marklip) project for license information.

## Contributing

Issues and pull requests are welcome on the [GitHub repository](https://github.com/dayflower/marklip-launcher).
