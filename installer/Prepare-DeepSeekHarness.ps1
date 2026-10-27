param([string]$InstallDir = 'D:\Apps\DeepSeek Harness')

$ErrorActionPreference = 'Stop'
$legacyDir = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness'
$installDir = [IO.Path]::GetFullPath($InstallDir).TrimEnd('\')
$appRelative = 'desktop\DeepSeek Harness-win32-arm64\DeepSeek Harness.exe'
$cliRelative = 'runtime\node_modules\@deepseek-ai\dsh\lib\bin.js'
$exe = Join-Path $installDir $appRelative

if ([IO.Path]::GetPathRoot($installDir) -eq $installDir) {
  throw '不能把程序安装在磁盘根目录。'
}
if ((Test-Path -LiteralPath $installDir) -and
    (Get-ChildItem -LiteralPath $installDir -Force | Where-Object Name -ne '_installer' | Select-Object -First 1) -and
    -not (Test-Path -LiteralPath (Join-Path $installDir '.deepseek-harness-arm64-install')) -and
    -not (Test-Path -LiteralPath $exe)) {
  throw '所选文件夹已有其他文件，请选择空文件夹。'
}

$roots = @($installDir, $legacyDir) | Select-Object -Unique
$appPaths = @($roots | ForEach-Object { Join-Path $_ $appRelative })
$cliPaths = @($roots | ForEach-Object { Join-Path $_ $cliRelative })
$processes = @(Get-CimInstance Win32_Process)
foreach ($process in $processes) {
  if ($process.ExecutablePath -and $appPaths -contains $process.ExecutablePath) {
    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
  }
}
$deadline = (Get-Date).AddSeconds(15)
do {
  $remainingApps = @(Get-CimInstance Win32_Process | Where-Object {
    $_.ExecutablePath -and $appPaths -contains $_.ExecutablePath
  })
  if (-not $remainingApps) { break }
  Start-Sleep -Milliseconds 250
} while ((Get-Date) -lt $deadline)
if ($remainingApps) { throw '旧版应用未能退出，请先从托盘完全退出。' }
foreach ($process in $processes) {
  if ($process.Name -ne 'node.exe' -or -not $process.CommandLine) { continue }
  foreach ($cliPath in $cliPaths) {
    if ($process.CommandLine.IndexOf($cliPath, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
    & taskkill.exe /PID $process.ProcessId /T /F | Out-Null
    if ($LASTEXITCODE -ne 0 -and (Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue)) {
      throw "旧服务未能退出，进程 ID：$($process.ProcessId)"
    }
    break
  }
}

$statePath = Join-Path $env:LOCALAPPDATA 'DeepSeekHarness\launcher\server.json'
if (Test-Path -LiteralPath $statePath) { Remove-Item -LiteralPath $statePath -Force }
