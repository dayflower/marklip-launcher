# Development Guide

Developer-facing notes for building, releasing, and understanding Marklip Launcher.
For end-user installation and usage, see the [README](../README.md).

## Overview & Requirements

Marklip Launcher is a macOS status bar app written in Swift. It is a thin GUI over
the [marklip](https://github.com/dayflower/marklip) CLI for clipboard-based
Markdown/HTML conversion.

- Built with Swift Package Manager — there is no Xcode project.
- Deployment target: macOS 13.0+ (`Package.swift`).
- Runtime dependency: the `marklip` command, installed separately via Homebrew
  (`brew install dayflower/tap/marklip`).
- **Xcode requirement:** compiling the Swift code only needs the Command Line
  Tools, but building the **app icon** requires a full **Xcode (actool >= 26)**.
  See [App Bundle & Icon Build](#app-bundle--icon-build).

## Build & Development Commands

All workflows go through the [Makefile](../Makefile):

| Command | Description |
| --- | --- |
| `make build` | Build the release `.app` via `Scripts/bundle-app.sh`, then ad-hoc codesign it. Output: `.build/release/Marklip Launcher.app` |
| `make install` | Build and copy the `.app` to `~/Applications/` |
| `make run` | Build and `open` the app |
| `make debug` | `swift build` (debug) and run the raw executable |
| `make clean` | `swift package clean` and remove the built `.app` |
| `make uninstall` | Remove the `.app` from `~/Applications/` |
| `make check` | `swift-format lint --strict` — identical to CI |
| `make fix` | `swift-format format --in-place` |

Run `make check` before pushing; CI runs the same lint and will fail otherwise.

## Architecture

Dependency flow:

```
main.swift
  └─> AppDelegate
       └─> StatusBarController
            ├─> MarklipExecutor ──> NotificationManager
            └─> LaunchAgentManager ─> NotificationManager
```

Components (`Sources/MarklipLauncher/`):

- **main.swift** — entry point; creates an `NSApplication` with `.accessory`
  activation policy (no Dock icon).
- **AppDelegate** — app lifecycle; wires up managers and the controller.
- **StatusBarController** — builds the status bar menu and handles interactions.
- **MarklipExecutor** — runs `marklip` via `Process`; reports results as notifications.
- **LaunchAgentManager** — creates/removes the LaunchAgent plist in `~/Library/LaunchAgents/`.
- **NotificationManager** — wraps the `UserNotifications` framework (permission
  handling + foreground delivery via `UNUserNotificationCenterDelegate`).
- **Constants** — bundle id (`com.example.dayflower.marklipLauncher`), app name,
  and command name. See [Constants.swift](../Sources/MarklipLauncher/Constants.swift);
  the same identifiers live in [Resources/Info.plist](../Resources/Info.plist).

## marklip Integration

The three conversion menu items map to marklip subcommands:

- **Auto** → `marklip auto`
- **Convert to HTML** → `marklip to-html`
- **Convert to markdown** → `marklip to-md`

Key point: **the launcher does not pipe data through stdin/stdout.** marklip reads
and writes the system clipboard directly. The launcher's only responsibilities are
to locate and run the command, detect failures (exit status / stderr), and notify
the user.

Menu items are enabled/disabled dynamically based on clipboard contents
(HTML present / non-empty text) each time the menu opens.

`marklip` is located via `/usr/bin/which`; if it is not on `PATH`, conversions
fail with an error notification.

## App Bundle & Icon Build

`make build` runs [Scripts/bundle-app.sh](../Scripts/bundle-app.sh), which:

1. `swift build -c release` and copies the executable into the bundle.
2. Copies `Resources/Info.plist` into `Contents/`.
3. Compiles the app icon and merges the icon keys into the bundle plist.

Resulting structure:

```
Marklip Launcher.app/
└── Contents/
    ├── MacOS/marklip-launcher   (executable)
    ├── Resources/Assets.car     (compiled app icon)
    └── Info.plist
```

The icon source is `icons/AppIcon.icon`, an **Icon Composer** document. `actool`
compiles it into `Assets.car`, and its partial plist is merged via `PlistBuddy`.

**Non-obvious pitfalls:**

- Requires a **full Xcode with actool >= 26** (Icon Composer support). Command Line
  Tools alone will fail.
- The icon compile uses `--minimum-deployment-target 26.0` — intentionally separate
  from the app's own macOS 13 target. With an older target, actool emits **no icon
  and still exits 0** (silent failure).
- The script runs `killall ibtoold` first to clear a stuck actool daemon that can
  otherwise silently produce nothing.

## Versioning & Release

**Single source of truth:** `Resources/Info.plist` — keep
`CFBundleShortVersionString` and `CFBundleVersion` in sync (this project uses no
separate build number).

Release process:

1. On `main` with a clean tree, run [Scripts/bump-version.sh](../Scripts/bump-version.sh)
   with a version (`0.3.0`) or a keyword (`patch` / `minor` / `major`). It creates a
   `bump-version-vX.Y.Z` branch, bumps the plist, and opens a PR via `gh`.
2. Merge the PR into `main`. That triggers
   [.github/workflows/release.yml](../.github/workflows/release.yml), which reads the
   version, and if no matching tag exists: tags `vX.Y.Z`, runs `make build`, zips the
   `.app`, publishes a GitHub Release (auto-generated notes), and updates the Homebrew
   tap (`dayflower/homebrew-tap`).

The release job runs on the **`macos-26`** runner because of the actool >= 26
requirement above. On ordinary pushes (version unchanged), the workflow exits early.

## Code Signing & Distribution

The app uses **ad-hoc signing** (`codesign --sign -`) — no Apple Developer ID. This
is fine for local use, but downloaded copies are quarantined by Gatekeeper, so users
must run `xattr -cr "Marklip Launcher.app"` after downloading (documented in the
README and Homebrew cask). Local notifications need no entitlements.

## CI

[.github/workflows/ci.yml](../.github/workflows/ci.yml) runs `make check`
(swift-format lint) on every pull request and push to `main`.
