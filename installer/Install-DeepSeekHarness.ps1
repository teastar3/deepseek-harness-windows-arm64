param(
  [string]$InstallDir = 'D:\Apps\DeepSeek Harness',
  [switch]$NoLaunch
)

$ErrorActionPreference = 'Stop'
$productName = 'DeepSeek Harness'
$installDir = [IO.Path]::GetFullPath($InstallDir).TrimEnd('\')
$appRelative = 'desktop\DeepSeek Harness-win32-arm64\DeepSeek Harness.exe'
$cliRelative = 'runtime\node_modules\@deepseek-ai\dsh\lib\bin.js'
$nodeRelative = 'node-v24.22.1-win-arm64\node.exe'
$exe = Join-Path $installDir $appRelative
$icon = Join-Path $installDir 'desktop\DeepSeek Harness-win32-arm64\resources\app\deepseek-whale.ico'
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\DeepSeek Harness'
$uninstallKeyPath = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\DeepSeekHarnessArm64'
$appPathsKeyPath = 'Software\Microsoft\Windows\CurrentVersion\App Paths\DeepSeek Harness.exe'
$protocolKeyPath = 'Software\Classes\dsh'

foreach ($relative in @($appRelative, $cliRelative, $nodeRelative)) {
  if (-not (Test-Path -LiteralPath (Join-Path $installDir $relative) -PathType Leaf)) {
    throw "安装包不完整：$relative"
  }
}

$marker = Join-Path $installDir '.deepseek-harness-arm64-install'
Set-Content -LiteralPath $marker -Value 'DeepSeek Harness Windows ARM64' -Encoding UTF8

$shortcutShell = New-Object -ComObject WScript.Shell
New-Item -ItemType Directory -Force -Path $startMenu | Out-Null
$shortcut = $shortcutShell.CreateShortcut((Join-Path $startMenu 'DeepSeek Harness.lnk'))
$shortcut.TargetPath = $exe
$shortcut.WorkingDirectory = Split-Path -Parent $exe
$shortcut.IconLocation = $icon
$shortcut.Description = $productName
$shortcut.Save()
$desktopPath = [Environment]::GetFolderPath('Desktop')
if ($desktopPath) {
  $desktopShortcut = $shortcutShell.CreateShortcut((Join-Path $desktopPath 'DeepSeek Harness.lnk'))
  $desktopShortcut.TargetPath = $exe
  $desktopShortcut.WorkingDirectory = Split-Path -Parent $exe
  $desktopShortcut.IconLocation = $icon
  $desktopShortcut.Description = $productName
  $desktopShortcut.Save()
}
$uninstallShortcut = $shortcutShell.CreateShortcut((Join-Path $startMenu '卸载 DeepSeek Harness.lnk'))
$uninstallShortcut.TargetPath = Join-Path $installDir '卸载 DeepSeek Harness.cmd'
$uninstallShortcut.WorkingDirectory = $env:TEMP
$uninstallShortcut.Description = '卸载 DeepSeek Harness ARM64'
$uninstallShortcut.Save()

$oldShortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\DeepSeek Harness.lnk'
if (Test-Path -LiteralPath $oldShortcutPath) {
  $oldShortcut = $shortcutShell.CreateShortcut($oldShortcutPath)
  if ($oldShortcut.TargetPath -eq $exe -or $oldShortcut.TargetPath -eq (Join-Path $env:LOCALAPPDATA ('Programs\DeepSeek Harness\' + $appRelative))) {
    Remove-Item -LiteralPath $oldShortcutPath -Force
  }
}

$protocol = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($protocolKeyPath)
try {
  $protocol.SetValue('', 'URL:DeepSeek Harness Protocol')
  $protocol.SetValue('URL Protocol', '')
  $defaultIcon = $protocol.CreateSubKey('DefaultIcon')
  try { $defaultIcon.SetValue('', ('"{0}",0' -f $icon)) } finally { $defaultIcon.Close() }
  $openCommand = $protocol.CreateSubKey('shell\open\command')
  try { $openCommand.SetValue('', ('"{0}" "%1"' -f $exe)) } finally { $openCommand.Close() }
} finally { $protocol.Close() }

$appPathsKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($appPathsKeyPath)
try {
  $appPathsKey.SetValue('', $exe)
  $appPathsKey.SetValue('Path', (Split-Path -Parent $exe))
} finally { $appPathsKey.Close() }

$uninstallKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($uninstallKeyPath)
try {
  $uninstallKey.SetValue('DisplayName', 'DeepSeek Harness (ARM64)')
  $uninstallKey.SetValue('DisplayVersion', '0.2.1-rc.2')
  $uninstallKey.SetValue('Publisher', 'DeepSeek Harness ARM64 community build')
  $uninstallKey.SetValue('InstallLocation', $installDir)
  $uninstallKey.SetValue('DisplayIcon', $exe)
  $uninstallCommand = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $installDir 'Uninstall-DeepSeekHarness.ps1')
  $uninstallKey.SetValue('UninstallString', $uninstallCommand)
  $uninstallKey.SetValue('QuietUninstallString', ($uninstallCommand + ' -Quiet'))
  $uninstallKey.SetValue('NoModify', 1, [Microsoft.Win32.RegistryValueKind]::DWord)
  $uninstallKey.SetValue('NoRepair', 1, [Microsoft.Win32.RegistryValueKind]::DWord)
  $uninstallKey.SetValue('InstallDate', (Get-Date -Format yyyyMMdd))
} finally { $uninstallKey.Close() }

if (-not $NoLaunch) { Start-Process -FilePath $exe }
Write-Host "DeepSeek Harness ARM64 已安装到 $installDir"
