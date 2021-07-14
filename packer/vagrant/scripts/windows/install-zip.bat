:: source download http://www.7-zip.org/a/7z920-x64.msi
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/7z920-x64.msi', 'C:\Windows\Temp\7z920-x64.msi')" <NUL

msiexec /qb /i C:\Windows\Temp\7z920-x64.msi
