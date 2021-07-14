::::::::::::
:main
::::::::::::

:: download source https://downloads.sourceforge.net/ultradefrag/ultradefrag-portable-7.0.2.bin.amd64.zip
set ULTRADEFRAG_URL=https://vagrant-public-cache.s3.amazonaws.com/ultradefrag-portable-7.0.2.bin.amd64.zip

for %%i in ("%ULTRADEFRAG_URL%") do set ULTRADEFRAG_ZIP=%%~nxi
set ULTRADEFRAG_DIR=%TEMP%\ultradefrag
set ULTRADEFRAG_PATH=%ULTRADEFRAG_DIR%\%ULTRADEFRAG_ZIP%

echo ==^> Creating "%ULTRADEFRAG_DIR%"
mkdir "%ULTRADEFRAG_DIR%"
pushd "%ULTRADEFRAG_DIR%"

echo ==^> Downloading "%ULTRADEFRAG_URL%" to "%ULTRADEFRAG_PATH%"
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('%ULTRADEFRAG_URL%', '%ULTRADEFRAG_PATH%')" <NUL

echo ==^> Unzipping "%ULTRADEFRAG_PATH%" to "%ULTRADEFRAG_DIR%"
"C:\Program Files\7-Zip\7z.exe" e -y -o"%ULTRADEFRAG_DIR%" "%ULTRADEFRAG_PATH%" *\udefrag.exe *\*.dll

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
