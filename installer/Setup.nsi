Unicode true
!include "MUI2.nsh"

Name "DeepSeek Harness ARM64"
OutFile "DeepSeek-Harness-ARM64-Setup.exe"
InstallDir "D:\Apps\DeepSeek Harness"
RequestExecutionLevel user
Icon "payload\assets\deepseek-whale.ico"
SetCompressor zlib
ShowInstDetails show

VIProductVersion "0.2.1.2"
VIAddVersionKey "ProductName" "DeepSeek Harness ARM64"
VIAddVersionKey "FileDescription" "DeepSeek Harness ARM64 installer"
VIAddVersionKey "FileVersion" "0.2.1.2"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE "SimpChinese"

Section "安装"
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  File "Prepare-DeepSeekHarness.ps1"
  File "Install-DeepSeekHarness.ps1"

  DetailPrint "关闭旧版 DeepSeek Harness..."
  ExecWait '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\Prepare-DeepSeekHarness.ps1" -InstallDir "$INSTDIR"' $0
  IntCmp $0 0 prepared
  MessageBox MB_ICONSTOP "安装准备失败。错误码：$0"
  Abort

  prepared:
  DetailPrint "安装应用和运行环境..."
  SetOutPath "$INSTDIR"
  File /r "payload\*"
  File "Uninstall-DeepSeekHarness.ps1"
  File "卸载 DeepSeek Harness.cmd"

  DetailPrint "创建桌面图标、开始菜单和卸载入口..."
  ExecWait '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\Install-DeepSeekHarness.ps1" -InstallDir "$INSTDIR"' $0
  IntCmp $0 0 success
  MessageBox MB_ICONSTOP "安装未完成，请查看安装详情。错误码：$0"
  Abort

  success:
SectionEnd
