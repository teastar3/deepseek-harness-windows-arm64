# File layout and privacy review

## Repository

| Path | Contents |
| --- | --- |
| `desktop/main.js` | Electron window, tray, local server lifecycle, notification identity, and link handling. |
| `desktop/deepseek-whale.ico` | Desktop and installer icon. |
| `desktop/package.json`, `desktop/package-lock.json` | Desktop build dependencies and pinned versions. |
| `runtime/package.json`, `runtime/package-lock.json` | Harness runtime dependency and pinned transitive versions. |
| `installer/Setup.nsi` | NSIS installer definition and default installation directory. |
| `installer/*.ps1`, `installer/*.cmd` | Install preparation, Windows integration, uninstall, and launch helpers. |

## Installer payload

The release installer contains these directories and files, extracted from the actual `.exe` for review:

| Path in installer | Purpose |
| --- | --- |
| `assets/` | Installer icon and artwork. |
| `desktop/DeepSeek Harness-win32-arm64/` | Packaged Electron ARM64 executable, app source, Chromium files, and Electron license notices. |
| `node-v24.22.1-win-arm64/` | Official Windows ARM64 Node.js distribution, including npm and its licenses. |
| `runtime/node_modules/` | Published DeepSeek Harness npm packages and transitive dependencies. |
| `runtime/package.json`, `runtime/package-lock.json` | Runtime dependency metadata. |
| `Uninstall-DeepSeekHarness.ps1`, `卸载 DeepSeek Harness.cmd` | Files used by the uninstaller. |
| `$PLUGINSDIR/` | Temporary NSIS components and installation scripts used during setup. |

The extracted installer has **65,819 files** totaling **1,170,755,355 uncompressed bytes**. The installer itself is **327,704,371 bytes** and has SHA-256 `d2ed95875bd973010442aabed2a4be094b72feaf1a8fda709e1d58c3ea69457f`.

## User data

At runtime, Harness creates its configuration, sessions, and plugins in the user's own profile; the launcher stores its local server state and logs under `%LOCALAPPDATA%\DeepSeekHarness\launcher`. The wrapper uses `%USERPROFILE%\Documents\DeepSeek Harness Projects` as its default working directory. None of these runtime directories are included in the repository or installer. Uninstalling preserves them.

## Review performed for this release

The distributed `.exe` was opened as an NSIS archive and its extracted file list was inspected. The release file and the prebuilt copy beside `installer/Setup.nsi` have identical SHA-256 hashes. The extracted files were checked for the builder's Windows user path, work directory path, a known locally installed plugin name, common credential filenames, and GitHub token patterns. No matches were found for those personal indicators. A zero-byte `.npmrc` in the Node.js npm distribution is a stock package file.

This is a targeted review of the supplied installer, not a guarantee that every third-party package is free of sample data or vulnerabilities. Users rebuilding the installer should repeat the review for their own payload.
