@echo off
SETLOCAL
SET DIR=%~dp0%

powershell.exe ^
    -ExecutionPolicy Unrestricted ^
    -NoLogo ^
    -NoProfile ^
    -Command "& '%DIR%run.ps1' %*"
