if not exist "C:\Windows\Temp\git.exe" (
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.13.0.windows.1/Git-2.13.0-64-bit.exe', 'C:\Windows\Temp\git.exe')" <NUL
)

powershell -Command "Start-Process 'C:\Windows\Temp\git.exe' '/quiet /norestart' -Wait"
