powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/buildtools-sdk.zip', 'C:\Windows\Temp\build-tools.zip')" <NUL

mkdir C:\Windows\Temp\build-tools-installer
"C:\Program Files\7-Zip\7z.exe" x -y -o"C:\Windows\Temp\build-tools-installer" C:\Windows\Temp\build-tools.zip

start /wait c:\Windows\Temp\build-tools-installer\visualcppbuildtools_full.exe /adminfile a:\buildtools-adminfile.xml /passive /norestart /norefresh

setx PATH "%PATH%;C:\Program Files (x86)\Windows Kits\8.1\bin\x86" /m
setx PATH "%PATH%;c:\hashicorp\tools" /m
