@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall-DeepSeekHarness.ps1"
if errorlevel 1 pause
