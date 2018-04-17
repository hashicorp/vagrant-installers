[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12
Write-Host "Downloading Build Tools"
(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/5/f/7/5f7acaeb-8363-451f-9425-68a90f98b238/visualcppbuildtools_full.exe', 'C:\Windows\Temp\build-tools.exe')
Write-Host "Installing Build Tools"
Start-Process "C:\Windows\Temp\build-tools.exe" "/Passive /AdminFile A:\buildtools-adminfile.xml" -Wait
