const { app, BrowserWindow, shell, dialog, Menu, Tray, nativeImage } = require('electron')
const { spawn, execFileSync } = require('node:child_process')
const fs = require('node:fs')
const path = require('node:path')

const installDir = app.isPackaged
  ? path.resolve(process.resourcesPath, '..', '..', '..')
  : process.env.DSH_INSTALL_DIR
const stateDir = path.join(process.env.LOCALAPPDATA || app.getPath('userData'), 'DeepSeekHarness', 'launcher')
const statePath = path.join(stateDir, 'server.json')
const iconPath = path.join(__dirname, 'deepseek-whale.ico')
const appUserModelId = 'com.deepseek.harness.arm64'
const toastActivatorClsid = '{BEFE1887-806B-450D-A34E-72787AECD504}'
let mainWindow
let tray
let serverPid
let isQuitting = false
let restarting = false
const externalWindows = new Set()

if (process.platform === 'win32') {
  app.setAppUserModelId(appUserModelId)
  app.setToastActivatorCLSID(toastActivatorClsid)
}

function showWindow() {
  if (!mainWindow || mainWindow.isDestroyed()) return
  mainWindow.show()
  if (mainWindow.isMinimized()) mainWindow.restore()
  mainWindow.focus()
}

function isHarnessServer(pid) {
  if (!Number.isInteger(pid) || pid <= 0) return false
  try {
    const commandLine = execFileSync('powershell.exe', ['-NoProfile', '-Command',
      `(Get-CimInstance Win32_Process -Filter 'ProcessId=${pid}').CommandLine`],
    { encoding: 'utf8', timeout: 5000, windowsHide: true })
    const cli = path.join(installDir, 'runtime', 'node_modules', '@deepseek-ai', 'dsh', 'lib', 'bin.js')
    return commandLine.toLowerCase().includes(cli.toLowerCase())
  } catch { return false }
}

function stopServer() {
  if (serverPid && isHarnessServer(serverPid)) {
    try {
      execFileSync('taskkill.exe', ['/PID', String(serverPid), '/T', '/F'],
        { timeout: 10000, windowsHide: true, stdio: 'ignore' })
    } catch (error) { console.warn('DeepSeek Harness 服务未能完全退出', error) }
  }
  serverPid = undefined
  try { fs.unlinkSync(statePath) } catch (error) { if (error.code !== 'ENOENT') console.warn(error) }
}

async function restartServer() {
  if (restarting) return
  restarting = true
  try {
    stopServer()
    const serverUrl = await getServerUrl()
    await mainWindow.loadURL(serverUrl)
    showWindow()
  } catch (error) {
    dialog.showErrorBox('DeepSeek Harness 重启失败', error.message)
  } finally { restarting = false }
}

function createTray() {
  tray = new Tray(nativeImage.createFromPath(iconPath))
  tray.setToolTip('DeepSeek Harness')
  tray.setContextMenu(Menu.buildFromTemplate([
    { label: '打开 DeepSeek Harness', click: showWindow },
    { label: '重启 DeepSeek Harness 服务', click: () => { void restartServer() } },
    { type: 'separator' },
    { label: '完全退出 DeepSeek Harness', click: () => app.quit() }
  ]))
  tray.on('click', showWindow)
  tray.on('double-click', showWindow)
}

function registerWindowsIntegration() {
  if (process.platform !== 'win32' || !app.isPackaged) return
  if (!app.setAsDefaultProtocolClient('dsh')) console.warn('dsh:// 协议注册失败')
  const shortcutPath = path.join(app.getPath('appData'), 'Microsoft', 'Windows', 'Start Menu',
    'Programs', 'DeepSeek Harness', 'DeepSeek Harness.lnk')
  fs.mkdirSync(path.dirname(shortcutPath), { recursive: true })
  if (!shell.writeShortcutLink(shortcutPath, 'create', {
    target: process.execPath,
    cwd: path.dirname(process.execPath),
    description: 'DeepSeek Harness',
    icon: iconPath,
    iconIndex: 0,
    appUserModelId,
    toastActivatorClsid
  })) console.warn('Windows 通知快捷方式注册失败')
}

if (!app.requestSingleInstanceLock()) {
  app.quit()
} else {
  app.on('second-instance', () => { showWindow() })

  app.whenReady().then(async () => {
    try {
      Menu.setApplicationMenu(null)
      fs.mkdirSync(stateDir, { recursive: true })
      registerWindowsIntegration()
      const serverUrl = await getServerUrl()
      createWindow(serverUrl)
      createTray()
    } catch (error) {
      dialog.showErrorBox('DeepSeek Harness 启动失败', error.message)
      app.quit()
    }
  })

  app.on('activate', showWindow)
  app.on('before-quit', () => { isQuitting = true; stopServer(); tray?.destroy() })
}

function validServerUrl(value) {
  return typeof value === 'string' &&
    /^http:\/\/127\.0\.0\.1:\d+\/\?token=[A-Za-z0-9_-]+$/.test(value)
}

async function getServerUrl() {
  if (fs.existsSync(statePath)) {
    try {
      const state = JSON.parse(fs.readFileSync(statePath, 'utf8'))
      const cachedUrl = state.url || state.Url
      if (validServerUrl(cachedUrl) && isHarnessServer(state.processId)) {
        const origin = new URL(cachedUrl).origin
        const response = await fetch(cachedUrl, { signal: AbortSignal.timeout(3000) })
        if (response.ok) {
          serverPid = state.processId
          return cachedUrl
        }
      }
    } catch {}
  }

  if (!installDir) throw new Error('找不到 DeepSeek Harness 安装目录。')
  const nodeDir = path.join(installDir, 'node-v24.22.1-win-arm64')
  const nodeExe = path.join(nodeDir, 'node.exe')
  const cli = path.join(installDir, 'runtime', 'node_modules', '@deepseek-ai', 'dsh', 'lib', 'bin.js')
  if (!fs.existsSync(nodeExe) || !fs.existsSync(cli)) {
    throw new Error('DeepSeek Harness 运行文件不完整。')
  }

  const workspace = path.join(app.getPath('documents'), 'DeepSeek Harness Projects')
  fs.mkdirSync(workspace, { recursive: true })
  const logPath = path.join(stateDir, `server-${Date.now()}.log`)
  const logHandle = fs.openSync(logPath, 'w')
  const child = spawn(nodeExe, [cli, 'web', '--host', '127.0.0.1', '--port', '0', '--no-open'], {
    cwd: workspace,
    env: { ...process.env, PATH: `${nodeDir};${process.env.PATH || ''}` },
    detached: true,
    windowsHide: true,
    stdio: ['ignore', logHandle, logHandle]
  })
  fs.closeSync(logHandle)
  child.unref()
  serverPid = child.pid

  const deadline = Date.now() + 60000
  while (Date.now() < deadline) {
    const output = fs.readFileSync(logPath, 'utf8')
    const match = output.match(/dsh web: (http:\/\/127\.0\.0\.1:\d+\/\?token=[A-Za-z0-9_-]+)/)
    if (match && validServerUrl(match[1])) {
      fs.writeFileSync(statePath, JSON.stringify({ processId: child.pid, url: match[1] }), 'utf8')
      return match[1]
    }
    if (child.exitCode !== null) {
      throw new Error(`Web 服务退出。请查看 ${logPath}`)
    }
    await new Promise(resolve => setTimeout(resolve, 250))
  }
  stopServer()
  throw new Error(`Web 服务启动超时。请查看 ${logPath}`)
}

function createWindow(serverUrl) {
  const serverOrigin = new URL(serverUrl).origin
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 840,
    minWidth: 900,
    minHeight: 650,
    show: false,
    backgroundColor: '#f6f7fb',
    icon: iconPath,
    title: 'DeepSeek Harness',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  })

  mainWindow.once('ready-to-show', () => mainWindow.show())
  mainWindow.on('close', (event) => {
    if (!isQuitting) {
      event.preventDefault()
      mainWindow.hide()
    }
  })
  mainWindow.loadURL(serverUrl)

  const popupOptions = {
    width: 1100,
    height: 780,
    icon: iconPath,
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  }

  const trackExternalWindow = (window) => {
    externalWindows.add(window)
    window.on('closed', () => externalWindows.delete(window))
    window.webContents.setWindowOpenHandler(({ url }) => {
      if (url === 'about:blank' || /^https?:\/\//.test(url)) {
        return { action: 'allow', overrideBrowserWindowOptions: popupOptions }
      }
      if (url.startsWith('mailto:')) shell.openExternal(url)
      return { action: 'deny' }
    })
    window.webContents.on('did-create-window', trackExternalWindow)
  }

  const openDestination = (destination) => {
    try {
      const url = new URL(destination)
      if (url.origin === serverOrigin) {
        mainWindow.loadURL(url.href)
      } else if (['https:', 'http:'].includes(url.protocol)) {
        const window = new BrowserWindow(popupOptions)
        trackExternalWindow(window)
        window.loadURL(url.href)
      } else if (url.protocol === 'mailto:') {
        shell.openExternal(url.href)
      }
    } catch {}
  }

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    try {
      if (new URL(url).origin === serverOrigin) {
        mainWindow.loadURL(url)
        return { action: 'deny' }
      }
    } catch {}
    if (url === 'about:blank' || /^https?:\/\//.test(url)) {
      return { action: 'allow', overrideBrowserWindowOptions: popupOptions }
    }
    if (url.startsWith('mailto:')) shell.openExternal(url)
    return { action: 'deny' }
  })
  mainWindow.webContents.on('did-create-window', trackExternalWindow)

  mainWindow.webContents.on('will-navigate', (event, destination) => {
    if (destination.startsWith('dsh://open')) {
      event.preventDefault()
      showWindow()
      return
    }
    try {
      if (new URL(destination).origin === serverOrigin) return
    } catch {}
    event.preventDefault()
    openDestination(destination)
  })
  mainWindow.webContents.on('will-frame-navigate', (details) => {
    if (details.url.startsWith('dsh://open')) {
      details.preventDefault()
      showWindow()
    }
  })
}
