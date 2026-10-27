# DeepSeek Harness for Windows ARM64

An unofficial Windows ARM64 desktop wrapper for the [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) web interface. It bundles an ARM64 Node.js runtime, the published `@deepseek-ai/dsh` npm package, and an Electron desktop shell. This project is not an official DeepSeek release or affiliated with DeepSeek.

## Download and install

Download `DeepSeek-Harness-ARM64-Setup.exe` from this repository's Releases page. The installer defaults to `D:\Apps\DeepSeek Harness`; choose another location if your computer has no D: drive. Installation is per user and does not require administrator privileges. Windows may warn about the unsigned community installer.

The installer creates a desktop shortcut, Start menu entries, a Windows uninstall entry, and a `dsh://` protocol registration. Closing the main window keeps the app running in the notification area. Its tray icon opens the app, restarts the local Harness service, or exits fully. The Electron shell registers a Windows notification identity and a Start menu shortcut for notification activation.

Use **Settings > Apps > Installed apps** or the Start menu uninstall shortcut to remove the app. Uninstalling leaves your user data and plugins intact.

## What is in the release?

See [FILES.md](FILES.md) for the installer layout and where user data is stored. The binary release contains third-party runtime components; [THIRD_PARTY.md](THIRD_PARTY.md) explains their licenses. The repository contains the wrapper and installer source plus dependency lockfiles, not a copy of the binary payload or anyone's personal configuration.

Release `v0.2.1-rc.2-arm64.1` uses DeepSeek Harness `0.2.1-rc.2`, Electron `44.7.0`, Node.js `24.22.1`, and NSIS `3.13`. The installer SHA-256 is `d2ed95875bd973010442aabed2a4be094b72feaf1a8fda709e1d58c3ea69457f`.

## Build from source

Build on Windows ARM64, preferably in a short directory such as `D:\dsh-build` because NSIS can fail when dependency paths are too long. Install Node.js 24 ARM64 and NSIS 3.13. The lockfiles pin the npm dependency versions.

1. Run `npm ci` in `runtime/` to install the Harness runtime and its dependencies.
2. Run `npm ci` in `desktop/` to install Electron and Electron Packager.
3. From `desktop/`, run `npx @electron/packager . "DeepSeek Harness" --platform=win32 --arch=arm64 --out=../installer/payload/desktop --overwrite --icon=deepseek-whale.ico`.
4. Copy the Node.js 24.22.1 Windows ARM64 distribution to `installer/payload/node-v24.22.1-win-arm64/` and the installed runtime files to `installer/payload/runtime/`. Keep `runtime/package.json`, `runtime/package-lock.json`, and `runtime/node_modules/` together. Put `desktop/deepseek-whale.ico` in `installer/payload/assets/`.
5. From `installer/`, run `makensis /INPUTCHARSET UTF8 Setup.nsi`. The installer appears in that directory.

Do not copy an existing `.dsh` directory, browser profile, credentials, or installed plugins into `installer/payload/`. Review your own build before distributing it. This source build may not be byte-for-byte identical to the release because Electron and npm packages can change their generated files or timestamps.

## License

The original wrapper and installer source in this repository is MIT-licensed; see [LICENSE](LICENSE). DeepSeek Harness, Electron, Node.js, NSIS, npm dependencies, and the upstream artwork have their own rights and notices. See [THIRD_PARTY.md](THIRD_PARTY.md).
