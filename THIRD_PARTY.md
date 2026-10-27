# Third-party components and licenses

The repository's MIT license applies to the original desktop wrapper and installer source. The binary installer also redistributes:

| Component | Release version | License and notice location |
| --- | --- | --- |
| DeepSeek Harness npm packages | `0.2.1-rc.2` | MIT, with package licenses under `runtime/node_modules/@deepseek-ai/`. |
| Electron and Chromium | `44.7.0` | Electron `LICENSE` and `LICENSES.chromium.html` in the packaged desktop directory. |
| Node.js and npm | `24.22.1` | `node-v24.22.1-win-arm64/LICENSE` and the licenses included in npm packages. |
| npm runtime dependencies | Versions pinned in `runtime/package-lock.json` | Each package's `license` field and bundled license file, where supplied. |
| npm build dependencies | Versions pinned in `desktop/package-lock.json` | Each package's `license` field and bundled license file, where supplied. |
| NSIS installer engine | `3.13` | NSIS zlib/libpng license; its distribution includes `COPYING`. |
| DeepSeek whale artwork | Included as an icon | Upstream brand artwork; the repository's MIT license does not grant trademark rights. |

The runtime lockfile lists 686 package records, including the project root. Licenses include MIT, Apache-2.0, BSD, ISC, MPL-2.0, LGPL-3.0-or-later, and others. Some dependencies use multiple licenses; consult the package's own notice for the applicable terms. Source code and notices for the DeepSeek Harness project are available from the [upstream repository](https://github.com/deepseek-ai/deepseek-harness).

The installer does not bundle user-installed Harness plugins. Plugins installed later by a user have their own licenses and are outside this release.
