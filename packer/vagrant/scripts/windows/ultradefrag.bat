if not defined ULTRADEFRAG_32_URL set ULTRADEFRAG_32_URL=http://downloads.sourceforge.net/ultradefrag/ultradefrag-portable-7.0.2.bin.i386.zip
if not defined ULTRADEFRAG_64_URL set ULTRADEFRAG_64_URL=http://downloads.sourceforge.net/ultradefrag/ultradefrag-portable-7.0.2.bin.amd64.zip

::::::::::::
:main
::::::::::::

if not exist "C:\Windows\Temp\7z920-x64.msi" (
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('http://www.7-zip.org/a/7z920-x64.msi', 'C:\Windows\Temp\7z920-x64.msi')" <NUL
    msiexec /qb /i C:\Windows\Temp\7z920-x64.msi
)

if defined ProgramFiles(x86) (
  set ULTRADEFRAG_URL=%ULTRADEFRAG_64_URL%
) else (
  set ULTRADEFRAG_URL=%ULTRADEFRAG_32_URL%
)

for %%i in ("%ULTRADEFRAG_URL%") do set ULTRADEFRAG_ZIP=%%~nxi
set ULTRADEFRAG_DIR=%TEMP%\ultradefrag
set ULTRADEFRAG_PATH=%ULTRADEFRAG_DIR%\%ULTRADEFRAG_ZIP%

echo ==^> Creating "%ULTRADEFRAG_DIR%"
mkdir "%ULTRADEFRAG_DIR%"
pushd "%ULTRADEFRAG_DIR%"

echo ==^> Downloading "%ULTRADEFRAG_URL%" to "%ULTRADEFRAG_PATH%"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%ULTRADEFRAG_URL%', '%ULTRADEFRAG_PATH%')" <NUL

echo ==^> Unzipping "%ULTRADEFRAG_PATH%" to "%ULTRADEFRAG_DIR%"
7z e -y -o"%ULTRADEFRAG_DIR%" "%ULTRADEFRAG_PATH%" *\udefrag.exe *\*.dll

@if errorlevel 1 echo ==^> WARNING: Error %ERRORLEVEL% was returned by: 7z e -o"%ULTRADEFRAG_DIR%" "%ULTRADEFRAG_PATH%"
ver>nul

for /r %%i in (udefrag.exe) do if exist "%%~i" set ULTRADEFRAG_EXE=%%~i

if not exist "%ULTRADEFRAG_EXE%" echo ==^> ERROR: File not found: udefrag.exe in "%ULTRADEFRAG_DIR%" & goto exit1

echo ==^> Running UltraDefrag on %SystemDrive%
"%ULTRADEFRAG_EXE%" --optimize --repeat %SystemDrive%

@if errorlevel 1 echo ==^> WARNING: Error %ERRORLEVEL% was returned by: "%ULTRADEFRAG_EXE%" --optimize --repeat %SystemDrive%
ver>nul

popd

echo ==^> Removing "%ULTRADEFRAG_DIR%"
rmdir /q /s "%ULTRADEFRAG_DIR%"

:exit0

@ping 127.0.0.1
@ver>nul

@goto :exit

:exit1

@ping 127.0.0.1
@verify other 2>nul

:exit

@echo ==^> Script exiting with errorlevel %ERRORLEVEL%
@exit /b %ERRORLEVEL%
