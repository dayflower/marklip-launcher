# marklip-launcher

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

This will create a release build at `.build/release/marklip-launcher`.

### Debug build

```bash
make debug
```

## Installation

### Install to /usr/local/bin

```bash
make install
```

This will copy the executable to `/usr/local/bin/marklip-launcher`.

### Uninstall

```bash
make uninstall
```

## Usage

### Running the application

```bash
marklip-launcher
```

Or if installed:

```bash
/usr/local/bin/marklip-launcher
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

To make marklip-launcher start automatically when you log in:

1. Click the status bar icon
2. Select **Configuration → Register as Startup Item**
3. A notification will confirm successful registration

The application will now start automatically at login.

To unregister:

1. Click the status bar icon
2. Select **Configuration → Unregister as Startup Item**

**Note**: The LaunchAgent stores the absolute path to the executable. If you move the executable after registration, you'll need to unregister and re-register.

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
