:: source download https://github.com/git-for-windows/git/releases/download/v2.13.0.windows.1/Git-2.13.0-64-bit.exe
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/Git-2.13.0-64-bit.exe', 'C:\Windows\Temp\git.exe')" <NUL

start /wait C:\Windows\Temp\git.exe /silent
