param([switch]$Quiet)

$ErrorActionPreference = 'Stop'
$installDir = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
$exe = Join-Path $installDir 'desktop\DeepSeek Harness-win32-arm64\DeepSeek Harness.exe'
$cli = Join-Path $installDir 'runtime\node_modules\@deepseek-ai\dsh\lib\bin.js'
$marker = Join-Path $installDir '.deepseek-harness-arm64-install'
$uninstallKeyPath = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\DeepSeekHarnessArm64'
$appPathsKeyPath = 'Software\Microsoft\Windows\CurrentVersion\App Paths\DeepSeek Harness.exe'
$protocolKeyPath = 'Software\Classes\dsh'
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\DeepSeek Harness'

$uninstallKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($uninstallKeyPath)
try {
  $registeredLocation = if ($uninstallKey) { $uninstallKey.GetValue('InstallLocation') } else { $null }
} finally { if ($uninstallKey) { $uninstallKey.Close() } }

if ([IO.Path]::GetPathRoot($installDir) -eq $installDir -or
    -not (Test-Path -LiteralPath $marker -PathType Leaf) -or
    $registeredLocation -ne $installDir) {
  throw '安装目录校验失败，已取消卸载。'
}

$processes = @(Get-CimInstance Win32_Process)
foreach ($process in $processes) {
  if ($process.ExecutablePath -and $process.ExecutablePath.Equals($exe, [StringComparison]::OrdinalIgnoreCase)) {
    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
  }
}
foreach ($process in $processes) {
  if ($process.Name -ne 'node.exe' -or -not $process.CommandLine -or
      $process.CommandLine.IndexOf($cli, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
  & taskkill.exe /PID $process.ProcessId /T /F | Out-Null
  if ($LASTEXITCODE -ne 0 -and (Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue)) {
    throw "服务未能退出，进程 ID：$($process.ProcessId)"
  }
}

$protocol = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($protocolKeyPath)
try {
  $command = if ($protocol) {
    $openCommand = $protocol.OpenSubKey('shell\open\command')
    try { if ($openCommand) { $openCommand.GetValue('') } } finally { if ($openCommand) { $openCommand.Close() } }
  } else { $null }
} finally { if ($protocol) { $protocol.Close() } }
if ($command -eq ('"{0}" "%1"' -f $exe)) {
  [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($protocolKeyPath, $false)
}
$appPathsKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($appPathsKeyPath)
try { $appPath = if ($appPathsKey) { $appPathsKey.GetValue('') } else { $null } }
finally { if ($appPathsKey) { $appPathsKey.Close() } }
if ($appPath -eq $exe) {
  [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($appPathsKeyPath, $false)
}
[Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($uninstallKeyPath, $false)

$shortcutShell = New-Object -ComObject WScript.Shell
foreach ($shortcutName in @('DeepSeek Harness.lnk', '卸载 DeepSeek Harness.lnk')) {
  $shortcutPath = Join-Path $startMenu $shortcutName
  if (-not (Test-Path -LiteralPath $shortcutPath)) { continue }
  $shortcut = $shortcutShell.CreateShortcut($shortcutPath)
  if ($shortcut.TargetPath.StartsWith($installDir + '\', [StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item -LiteralPath $shortcutPath -Force
  }
}
$desktopPath = [Environment]::GetFolderPath('Desktop')
if ($desktopPath) {
  $desktopShortcutPath = Join-Path $desktopPath 'DeepSeek Harness.lnk'
  if (Test-Path -LiteralPath $desktopShortcutPath) {
    $desktopShortcut = $shortcutShell.CreateShortcut($desktopShortcutPath)
    if ($desktopShortcut.TargetPath.Equals($exe, [StringComparison]::OrdinalIgnoreCase)) {
      Remove-Item -LiteralPath $desktopShortcutPath -Force
    }
  }
}
if ((Test-Path -LiteralPath $startMenu) -and -not (Get-ChildItem -LiteralPath $startMenu -Force)) {
  Remove-Item -LiteralPath $startMenu
}

Set-Location -LiteralPath $env:TEMP
Remove-Item -LiteralPath $installDir -Recurse -Force
if (-not $Quiet) { Write-Host 'DeepSeek Harness ARM64 已卸载。用户数据已保留。' }
