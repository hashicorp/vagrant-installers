if not exist "C:\Windows\Temp\wix.exe" (
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://github.com/wixtoolset/wix3/releases/download/wix3104rtm/wix310.exe', 'C:\Windows\Temp\wix.exe')" <NUL
)

powershell -Command "Start-Process 'C:\Windows\Temp\wix.exe' '/quiet /norestart' -Wait"

powershell -Command "$CurPath = [Environment]::GetEnvironmentVariable(\"PATH\"); [Environment]::SetEnvironmentVariable(\"PATH\", \"${CurPath};C:\Program Files (x86)\Wix Toolset v3.10\bin\", \"Machine\")"
