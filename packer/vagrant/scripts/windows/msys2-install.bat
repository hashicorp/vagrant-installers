if not exist "C:\Windows\Temp\msys2.exe" (
  powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://repo.msys2.org/distrib/x86_64/msys2-x86_64-20210228.exe', 'C:\Windows\Temp\msys2.exe')" <NUL
)

cmd /c "C:\Windows\Temp\msys2.exe -v --platform minimal --script A:\msys2-install.qs"

rem taskkill /IM "gpg-agent.exe" /F
rem taskkill /IM "dirmngr.exe" /F
