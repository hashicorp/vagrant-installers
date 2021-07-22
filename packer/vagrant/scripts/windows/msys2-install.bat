
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/msys2-x86_64-20210604.exe', 'C:\Windows\Temp\msys2.exe')" <NUL


cmd /c "C:\Windows\Temp\msys2.exe -d --platform minimal --script A:\msys2-install.qs"
