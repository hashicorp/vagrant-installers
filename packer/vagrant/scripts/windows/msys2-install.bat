if not exist "C:\Windows\Temp\msys2.exe" (
  powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://repo.msys2.org/distrib/x86_64/msys2-x86_64-20200720.exe', 'C:\Windows\Temp\msys2.exe')" <NUL
)

start /wait C:\Windows\Temp\msys2.exe --string A:\msys2-install.qs
