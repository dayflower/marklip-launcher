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

## Installation

### Option 1: Install via Homebrew (Recommended)

```bash
brew install --cask dayflower/tap/marklip-launcher
```

After installation, remove quarantine attributes:

```bash
xattr -cr "/Applications/Marklip Launcher.app"
```

This is required because the app uses ad-hoc code signing (no Apple Developer ID).

### Option 2: Download from GitHub Releases

1. **Download the latest release**

   Visit the [Releases page](https://github.com/dayflower/marklip-launcher/releases) and download the latest `Marklip-Launcher-x.x.x.zip`.

2. **Verify the download (optional)**

   ```bash
   shasum -a 256 -c Marklip-Launcher-x.x.x.zip.sha256
   ```

3. **Extract the archive**

   Double-click the zip file or use:

   ```bash
   unzip Marklip-Launcher-x.x.x.zip
   ```

4. **Remove quarantine attributes**

   **IMPORTANT**: This step is required because the app uses ad-hoc code signing:

   ```bash
   xattr -cr "Marklip Launcher.app"
   ```

   **Why is this needed?** macOS Gatekeeper applies quarantine attributes to downloaded files for security. Since this app is ad-hoc signed (no Apple Developer ID), you need to manually remove these attributes. Only do this for apps from trusted sources.

5. **Move to Applications folder**

   ```bash
   mv "Marklip Launcher.app" ~/Applications/
   ```

6. **Run the application**

   ```bash
   open ~/Applications/Marklip\ Launcher.app
   ```

### Option 3: Build from Source

See the [Building](#building) section below.

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

## Installing from Source Build

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

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Issues and pull requests are welcome on the [GitHub repository](https://github.com/dayflower/marklip-launcher).
